#!/usr/bin/env bash
###############################################################################
# bootstrap-backend.sh — Initialize Terraform S3 backend resources
#
# Creates the S3 bucket (with versioning, encryption, public access block) and
# DynamoDB table (for state locking) that Terraform needs before the first
# `terraform init` can succeed. Idempotent — safe to run multiple times.
#
# Usage:
#   ./scripts/bootstrap-backend.sh [OPTIONS]
#
# Options:
#   --bucket NAME          S3 bucket name (default: myapp-terraform-state)
#   --table NAME           DynamoDB table name (default: terraform-state-lock)
#   --region REGION        AWS region (default: us-east-1)
#   --profile PROFILE      AWS CLI profile to use
#   --dry-run              Show what would be created without creating
#   --help                 Show this help message
#
# Prerequisites:
#   - AWS CLI v2 installed and configured
#   - Sufficient IAM permissions for S3 and DynamoDB
###############################################################################
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
BUCKET_NAME="myapp-terraform-state"
TABLE_NAME="terraform-state-lock"
AWS_REGION="us-east-1"
AWS_PROFILE=""
DRY_RUN=false

# ---------------------------------------------------------------------------
# Colors
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
success() { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
die()     { error "$@"; exit 1; }

usage() {
  sed -n '/^# Usage:/,/^# Prerequisites:/p' "$0" | head -n -1 | sed 's/^# //' | sed 's/^#//'
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --bucket)   BUCKET_NAME="$2"; shift 2 ;;
    --table)    TABLE_NAME="$2"; shift 2 ;;
    --region)   AWS_REGION="$2"; shift 2 ;;
    --profile)  AWS_PROFILE="$2"; shift 2 ;;
    --dry-run)  DRY_RUN=true; shift ;;
    --help|-h)  usage ;;
    *)          die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ---------------------------------------------------------------------------
# Build AWS CLI base command
# ---------------------------------------------------------------------------
AWS_CMD="aws"
if [ -n "$AWS_PROFILE" ]; then
  AWS_CMD="aws --profile $AWS_PROFILE"
fi

# ---------------------------------------------------------------------------
# Verify AWS credentials
# ---------------------------------------------------------------------------
verify_credentials() {
  info "Verifying AWS credentials..."
  local identity
  identity=$($AWS_CMD sts get-caller-identity --output json 2>&1) || die "AWS credentials are not configured or have expired.\nRun 'aws configure' or export valid AWS credentials.\n\nError: $identity"

  local account_id arn
  account_id=$(echo "$identity" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
  arn=$(echo "$identity" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
  success "Authenticated as $arn (account: $account_id)"
}

# ---------------------------------------------------------------------------
# Create S3 bucket
# ---------------------------------------------------------------------------
create_bucket() {
  info "Checking S3 bucket: $BUCKET_NAME"

  if $AWS_CMD s3api head-bucket --bucket "$BUCKET_NAME" --region "$AWS_REGION" 2>/dev/null; then
    success "Bucket '$BUCKET_NAME' already exists"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would create S3 bucket: $BUCKET_NAME in $AWS_REGION"
    return 0
  fi

  info "Creating S3 bucket: $BUCKET_NAME"

  # Create the bucket (us-east-1 does not accept LocationConstraint)
  if [ "$AWS_REGION" = "us-east-1" ]; then
    $AWS_CMD s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION"
  else
    $AWS_CMD s3api create-bucket \
      --bucket "$BUCKET_NAME" \
      --region "$AWS_REGION" \
      --create-bucket-configuration "LocationConstraint=$AWS_REGION"
  fi

  # Enable versioning
  info "Enabling versioning on $BUCKET_NAME..."
  $AWS_CMD s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

  # Enable server-side encryption (AES-256)
  info "Enabling default encryption on $BUCKET_NAME..."
  $AWS_CMD s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
      "Rules": [{
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "aws:kms"
        },
        "BucketKeyEnabled": true
      }]
    }'

  # Block all public access
  info "Blocking public access on $BUCKET_NAME..."
  $AWS_CMD s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration '{
      "BlockPublicAcls": true,
      "IgnorePublicAcls": true,
      "BlockPublicPolicy": true,
      "RestrictPublicBuckets": true
    }'

  # Add lifecycle rule to clean up incomplete multipart uploads
  info "Adding lifecycle rules on $BUCKET_NAME..."
  $AWS_CMD s3api put-bucket-lifecycle-configuration \
    --bucket "$BUCKET_NAME" \
    --lifecycle-configuration '{
      "Rules": [{
        "ID": "AbortIncompleteMultipartUploads",
        "Status": "Enabled",
        "Filter": { "Prefix": "" },
        "AbortIncompleteMultipartUpload": {
          "DaysAfterInitiation": 7
        }
      }]
    }'

  success "S3 bucket '$BUCKET_NAME' created and configured"
}

# ---------------------------------------------------------------------------
# Create DynamoDB table
# ---------------------------------------------------------------------------
create_dynamodb_table() {
  info "Checking DynamoDB table: $TABLE_NAME"

  if $AWS_CMD dynamodb describe-table --table-name "$TABLE_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
    success "DynamoDB table '$TABLE_NAME' already exists"
    return 0
  fi

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would create DynamoDB table: $TABLE_NAME in $AWS_REGION"
    return 0
  fi

  info "Creating DynamoDB table: $TABLE_NAME"
  $AWS_CMD dynamodb create-table \
    --table-name "$TABLE_NAME" \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region "$AWS_REGION" \
    --tags Key=Purpose,Value=TerraformStateLock Key=ManagedBy,Value=bootstrap-script

  info "Waiting for table to become active..."
  $AWS_CMD dynamodb wait table-exists \
    --table-name "$TABLE_NAME" \
    --region "$AWS_REGION"

  # Enable point-in-time recovery
  info "Enabling point-in-time recovery..."
  $AWS_CMD dynamodb update-continuous-backups \
    --table-name "$TABLE_NAME" \
    --region "$AWS_REGION" \
    --point-in-time-recovery-specification PointInTimeRecoveryEnabled=true

  success "DynamoDB table '$TABLE_NAME' created and configured"
}

# ---------------------------------------------------------------------------
# Print summary
# ---------------------------------------------------------------------------
print_summary() {
  echo ""
  info "============================================"
  info "  Backend Bootstrap Summary"
  info "============================================"
  echo ""
  info "S3 Bucket:      $BUCKET_NAME"
  info "DynamoDB Table: $TABLE_NAME"
  info "Region:         $AWS_REGION"
  echo ""
  info "Add this to your Terraform backend configuration:"
  echo ""
  echo "  terraform {"
  echo "    backend \"s3\" {"
  echo "      bucket         = \"$BUCKET_NAME\""
  echo "      key            = \"<environment>/terraform.tfstate\""
  echo "      region         = \"$AWS_REGION\""
  echo "      dynamodb_table = \"$TABLE_NAME\""
  echo "      encrypt        = true"
  echo "    }"
  echo "  }"
  echo ""
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  info "============================================"
  info "  Terraform Backend Bootstrap"
  info "============================================"
  echo ""

  if [ "$DRY_RUN" = "true" ]; then
    warn "Running in DRY RUN mode. No resources will be created."
    echo ""
  fi

  verify_credentials
  echo ""
  create_bucket
  echo ""
  create_dynamodb_table

  print_summary

  success "Backend bootstrap complete."
}

main "$@"
