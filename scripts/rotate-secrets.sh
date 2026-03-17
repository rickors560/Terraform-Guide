#!/usr/bin/env bash
###############################################################################
# rotate-secrets.sh — Rotate secrets in AWS Secrets Manager
#
# Lists secrets for the specified environment, generates new random values,
# updates them in AWS Secrets Manager, and optionally restarts affected
# services on EKS to pick up the new values.
#
# Usage:
#   ./scripts/rotate-secrets.sh --env <environment> [OPTIONS]
#
# Options:
#   --env ENV            Target environment (dev, staging, prod) [required]
#   --secret NAME        Rotate a specific secret by name (can repeat)
#   --prefix PREFIX      Secret name prefix (default: myapp/<env>/)
#   --length N           Generated password length (default: 32)
#   --restart             Restart affected EKS deployments after rotation
#   --cluster NAME       EKS cluster name (default: myapp-cluster)
#   --namespace NS       Kubernetes namespace (default: myapp)
#   --region REGION      AWS region (default: us-east-1)
#   --profile PROFILE    AWS CLI profile to use
#   --dry-run            Show what would be rotated without making changes
#   --help               Show this help message
#
# Prerequisites:
#   - AWS CLI v2 with Secrets Manager permissions
#   - kubectl configured (if --restart is used)
###############################################################################
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
ENVIRONMENT=""
SECRET_NAMES=()
SECRET_PREFIX=""
PASSWORD_LENGTH=32
DO_RESTART=false
EKS_CLUSTER="myapp-cluster"
K8S_NAMESPACE="myapp"
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
    --env)       ENVIRONMENT="$2"; shift 2 ;;
    --secret)    SECRET_NAMES+=("$2"); shift 2 ;;
    --prefix)    SECRET_PREFIX="$2"; shift 2 ;;
    --length)    PASSWORD_LENGTH="$2"; shift 2 ;;
    --restart)   DO_RESTART=true; shift ;;
    --cluster)   EKS_CLUSTER="$2"; shift 2 ;;
    --namespace) K8S_NAMESPACE="$2"; shift 2 ;;
    --region)    AWS_REGION="$2"; shift 2 ;;
    --profile)   AWS_PROFILE="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --help|-h)   usage ;;
    *)           die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [ -z "$ENVIRONMENT" ]; then
  die "Missing required option: --env <environment>. Use --help for usage."
fi

case "$ENVIRONMENT" in
  dev|staging|prod) ;;
  *) die "Invalid environment: $ENVIRONMENT. Must be one of: dev, staging, prod" ;;
esac

if [ -z "$SECRET_PREFIX" ]; then
  SECRET_PREFIX="myapp/${ENVIRONMENT}/"
fi

if ! command -v aws >/dev/null 2>&1; then
  die "AWS CLI is not installed. Run ./scripts/setup.sh first."
fi

# ---------------------------------------------------------------------------
# Build AWS CLI base command
# ---------------------------------------------------------------------------
AWS_CMD="aws"
if [ -n "$AWS_PROFILE" ]; then
  AWS_CMD="aws --profile $AWS_PROFILE"
fi

# ---------------------------------------------------------------------------
# Generate a secure random value
# ---------------------------------------------------------------------------
generate_secret_value() {
  local length="${1:-$PASSWORD_LENGTH}"
  # Use /dev/urandom for high-quality randomness; include mixed character classes
  LC_ALL=C tr -dc 'A-Za-z0-9!@#$%^&*()_+=-' < /dev/urandom | head -c "$length" || true
}

# ---------------------------------------------------------------------------
# List secrets for the environment
# ---------------------------------------------------------------------------
list_secrets() {
  info "Listing secrets with prefix: $SECRET_PREFIX"

  $AWS_CMD secretsmanager list-secrets \
    --region "$AWS_REGION" \
    --filters "Key=name,Values=$SECRET_PREFIX" \
    --query 'SecretList[].{Name:Name,ARN:ARN,LastChanged:LastChangedDate,Description:Description}' \
    --output table
}

# ---------------------------------------------------------------------------
# Get secrets to rotate
# ---------------------------------------------------------------------------
get_target_secrets() {
  if [ ${#SECRET_NAMES[@]} -gt 0 ]; then
    # Use explicitly provided secret names
    printf '%s\n' "${SECRET_NAMES[@]}"
  else
    # Discover all secrets with the prefix
    $AWS_CMD secretsmanager list-secrets \
      --region "$AWS_REGION" \
      --filters "Key=name,Values=$SECRET_PREFIX" \
      --query 'SecretList[].Name' \
      --output text | tr '\t' '\n'
  fi
}

# ---------------------------------------------------------------------------
# Rotate a single secret
# ---------------------------------------------------------------------------
rotate_secret() {
  local secret_name="$1"
  local new_value

  info "Rotating secret: $secret_name"

  # Verify the secret exists
  if ! $AWS_CMD secretsmanager describe-secret \
      --secret-id "$secret_name" \
      --region "$AWS_REGION" >/dev/null 2>&1; then
    error "Secret not found: $secret_name"
    return 1
  fi

  # Get current secret value structure to preserve JSON keys
  local current_value
  current_value=$($AWS_CMD secretsmanager get-secret-value \
    --secret-id "$secret_name" \
    --region "$AWS_REGION" \
    --query 'SecretString' \
    --output text 2>/dev/null || echo "")

  # Check if the value is JSON (has key-value pairs)
  if echo "$current_value" | python3 -c "import sys,json; json.load(sys.stdin)" 2>/dev/null; then
    # It is JSON — regenerate each value while preserving keys
    new_value=$(echo "$current_value" | python3 -c "
import sys, json, secrets, string
data = json.load(sys.stdin)
charset = string.ascii_letters + string.digits + '!@#\$%^&*()_+=-'
for key in data:
    if isinstance(data[key], str):
        data[key] = ''.join(secrets.choice(charset) for _ in range($PASSWORD_LENGTH))
json.dump(data, sys.stdout)
")
  else
    # Plain string secret
    new_value=$(generate_secret_value "$PASSWORD_LENGTH")
  fi

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would update secret: $secret_name"
    return 0
  fi

  # Update the secret
  $AWS_CMD secretsmanager put-secret-value \
    --secret-id "$secret_name" \
    --secret-string "$new_value" \
    --region "$AWS_REGION" >/dev/null

  success "Rotated: $secret_name"
}

# ---------------------------------------------------------------------------
# Restart affected Kubernetes deployments
# ---------------------------------------------------------------------------
restart_services() {
  if [ "$DO_RESTART" != "true" ]; then
    return
  fi

  info "Restarting deployments in namespace $K8S_NAMESPACE..."

  if ! command -v kubectl >/dev/null 2>&1; then
    warn "kubectl is not installed. Skipping service restarts."
    return
  fi

  # Configure kubectl if cluster is specified
  if [ -n "$EKS_CLUSTER" ]; then
    info "Configuring kubectl for cluster: $EKS_CLUSTER"
    aws eks update-kubeconfig \
      --name "$EKS_CLUSTER" \
      --region "$AWS_REGION" \
      ${AWS_PROFILE:+--profile "$AWS_PROFILE"} \
      2>/dev/null || warn "Could not update kubeconfig for $EKS_CLUSTER"
  fi

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would restart deployments in namespace $K8S_NAMESPACE"
    return
  fi

  # Get all deployments in the namespace
  local deployments
  deployments=$(kubectl get deployments -n "$K8S_NAMESPACE" -o jsonpath='{.items[*].metadata.name}' 2>/dev/null || echo "")

  if [ -z "$deployments" ]; then
    warn "No deployments found in namespace $K8S_NAMESPACE"
    return
  fi

  for deployment in $deployments; do
    info "Restarting deployment: $deployment"
    kubectl rollout restart deployment/"$deployment" -n "$K8S_NAMESPACE"
  done

  # Wait for rollouts to complete
  for deployment in $deployments; do
    info "Waiting for deployment $deployment to be ready..."
    kubectl rollout status deployment/"$deployment" -n "$K8S_NAMESPACE" --timeout=300s || {
      error "Deployment $deployment did not become ready in time"
    }
  done

  success "All deployments restarted in $K8S_NAMESPACE"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  info "============================================"
  info "  Secret Rotation"
  info "============================================"
  echo ""
  info "Environment: $ENVIRONMENT"
  info "Prefix:      $SECRET_PREFIX"
  info "Region:      $AWS_REGION"

  if [ "$DRY_RUN" = "true" ]; then
    warn "Running in DRY RUN mode. No changes will be made."
  fi
  echo ""

  # Verify credentials
  info "Verifying AWS credentials..."
  $AWS_CMD sts get-caller-identity --region "$AWS_REGION" >/dev/null 2>&1 || \
    die "AWS credentials are not configured or have expired."
  success "AWS credentials verified"
  echo ""

  # List current secrets
  list_secrets
  echo ""

  # Get target secrets
  local targets
  targets=$(get_target_secrets)

  if [ -z "$targets" ]; then
    warn "No secrets found matching the criteria."
    exit 0
  fi

  # Rotate each secret
  local rotated=0
  local failed=0

  while IFS= read -r secret_name; do
    [ -z "$secret_name" ] && continue
    if rotate_secret "$secret_name"; then
      rotated=$((rotated + 1))
    else
      failed=$((failed + 1))
    fi
  done <<< "$targets"

  echo ""

  # Restart services if requested
  restart_services

  echo ""
  info "============================================"
  info "  Rotation Summary"
  info "============================================"
  echo ""
  info "Secrets rotated: $rotated"
  if [ "$failed" -gt 0 ]; then
    error "Secrets failed:  $failed"
  fi
  echo ""

  if [ "$failed" -gt 0 ]; then
    exit 1
  fi

  success "Secret rotation complete for $ENVIRONMENT."
}

main "$@"
