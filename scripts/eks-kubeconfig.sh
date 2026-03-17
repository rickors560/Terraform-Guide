#!/usr/bin/env bash
###############################################################################
# eks-kubeconfig.sh — Configure kubectl for an EKS cluster
#
# Updates the local kubeconfig to connect to the specified EKS cluster,
# verifies connectivity, and displays cluster information.
#
# Usage:
#   ./scripts/eks-kubeconfig.sh --cluster <name> [OPTIONS]
#
# Options:
#   --cluster NAME      EKS cluster name [required]
#   --region REGION     AWS region (default: us-east-1)
#   --profile PROFILE   AWS CLI profile to use
#   --alias ALIAS       Alias for the context in kubeconfig
#   --role-arn ARN      IAM role ARN to assume for cluster access
#   --namespace NS      Set default namespace for the context
#   --dry-run           Show commands without executing
#   --help              Show this help message
#
# Prerequisites:
#   - AWS CLI v2 with EKS permissions
#   - kubectl installed
###############################################################################
set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
CLUSTER_NAME=""
AWS_REGION="us-east-1"
AWS_PROFILE=""
CONTEXT_ALIAS=""
ROLE_ARN=""
DEFAULT_NAMESPACE=""
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
    --cluster)   CLUSTER_NAME="$2"; shift 2 ;;
    --region)    AWS_REGION="$2"; shift 2 ;;
    --profile)   AWS_PROFILE="$2"; shift 2 ;;
    --alias)     CONTEXT_ALIAS="$2"; shift 2 ;;
    --role-arn)  ROLE_ARN="$2"; shift 2 ;;
    --namespace) DEFAULT_NAMESPACE="$2"; shift 2 ;;
    --dry-run)   DRY_RUN=true; shift ;;
    --help|-h)   usage ;;
    *)           die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [ -z "$CLUSTER_NAME" ]; then
  die "Missing required option: --cluster <name>. Use --help for usage."
fi

for cmd in aws kubectl; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    die "$cmd is not installed. Run ./scripts/setup.sh first."
  fi
done

# ---------------------------------------------------------------------------
# Build AWS CLI arguments
# ---------------------------------------------------------------------------
AWS_ARGS=("--region" "$AWS_REGION")
if [ -n "$AWS_PROFILE" ]; then
  AWS_ARGS+=("--profile" "$AWS_PROFILE")
fi

# ---------------------------------------------------------------------------
# Verify AWS credentials
# ---------------------------------------------------------------------------
verify_credentials() {
  info "Verifying AWS credentials..."
  local identity
  identity=$(aws "${AWS_ARGS[@]}" sts get-caller-identity --output json 2>&1) || \
    die "AWS credentials are not configured or have expired.\n$identity"

  local account_id arn
  account_id=$(echo "$identity" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
  arn=$(echo "$identity" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
  success "Authenticated as $arn (account: $account_id)"
}

# ---------------------------------------------------------------------------
# Verify the EKS cluster exists
# ---------------------------------------------------------------------------
verify_cluster() {
  info "Verifying EKS cluster: $CLUSTER_NAME"

  local cluster_info
  cluster_info=$(aws "${AWS_ARGS[@]}" eks describe-cluster \
    --name "$CLUSTER_NAME" \
    --output json 2>&1) || die "EKS cluster '$CLUSTER_NAME' not found in region $AWS_REGION.\n$cluster_info"

  local status endpoint version
  status=$(echo "$cluster_info" | grep -o '"status": "[^"]*"' | head -1 | cut -d'"' -f4)
  endpoint=$(echo "$cluster_info" | grep -o '"endpoint": "[^"]*"' | cut -d'"' -f4)
  version=$(echo "$cluster_info" | grep -o '"version": "[^"]*"' | head -1 | cut -d'"' -f4)

  success "Cluster found: $CLUSTER_NAME"
  info "  Status:     $status"
  info "  Version:    $version"
  info "  Endpoint:   $endpoint"

  if [ "$status" != "ACTIVE" ]; then
    warn "Cluster status is $status (expected ACTIVE)"
  fi
}

# ---------------------------------------------------------------------------
# Update kubeconfig
# ---------------------------------------------------------------------------
update_kubeconfig() {
  info "Updating kubeconfig..."

  local cmd_args=("eks" "update-kubeconfig" "--name" "$CLUSTER_NAME" "${AWS_ARGS[@]}")

  if [ -n "$CONTEXT_ALIAS" ]; then
    cmd_args+=("--alias" "$CONTEXT_ALIAS")
  fi

  if [ -n "$ROLE_ARN" ]; then
    cmd_args+=("--role-arn" "$ROLE_ARN")
  fi

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would run: aws ${cmd_args[*]}"
    return
  fi

  aws "${cmd_args[@]}"

  local context_name="${CONTEXT_ALIAS:-arn:aws:eks:${AWS_REGION}:*:cluster/${CLUSTER_NAME}}"
  success "kubeconfig updated for cluster $CLUSTER_NAME"
  info "Context: $context_name"
}

# ---------------------------------------------------------------------------
# Set default namespace (if specified)
# ---------------------------------------------------------------------------
set_default_namespace() {
  if [ -z "$DEFAULT_NAMESPACE" ]; then
    return
  fi

  local context_name
  context_name=$(kubectl config current-context 2>/dev/null || echo "")

  if [ -z "$context_name" ]; then
    warn "No current context set; skipping namespace configuration"
    return
  fi

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would set default namespace to $DEFAULT_NAMESPACE"
    return
  fi

  kubectl config set-context "$context_name" --namespace="$DEFAULT_NAMESPACE" >/dev/null
  success "Default namespace set to $DEFAULT_NAMESPACE"
}

# ---------------------------------------------------------------------------
# Verify connectivity
# ---------------------------------------------------------------------------
verify_connection() {
  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would verify cluster connectivity"
    return
  fi

  info "Verifying cluster connectivity..."

  # Test API server connection
  if kubectl cluster-info >/dev/null 2>&1; then
    success "Successfully connected to the cluster"
  else
    warn "Could not connect to the cluster API server. Check network/VPN settings."
    return
  fi

  echo ""
  info "============================================"
  info "  Cluster Information"
  info "============================================"
  echo ""

  # Cluster info
  kubectl cluster-info 2>/dev/null || true
  echo ""

  # Node information
  info "Nodes:"
  kubectl get nodes -o wide 2>/dev/null || warn "Could not list nodes"
  echo ""

  # Namespace information
  info "Namespaces:"
  kubectl get namespaces 2>/dev/null || warn "Could not list namespaces"
  echo ""

  # Current context
  info "Current context: $(kubectl config current-context 2>/dev/null || echo 'unknown')"

  # Show available contexts
  info "Available contexts:"
  kubectl config get-contexts 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  info "============================================"
  info "  EKS Kubeconfig Setup"
  info "============================================"
  echo ""
  info "Cluster:   $CLUSTER_NAME"
  info "Region:    $AWS_REGION"
  if [ -n "$AWS_PROFILE" ]; then
    info "Profile:   $AWS_PROFILE"
  fi
  if [ -n "$ROLE_ARN" ]; then
    info "Role ARN:  $ROLE_ARN"
  fi
  if [ -n "$CONTEXT_ALIAS" ]; then
    info "Alias:     $CONTEXT_ALIAS"
  fi
  if [ -n "$DEFAULT_NAMESPACE" ]; then
    info "Namespace: $DEFAULT_NAMESPACE"
  fi

  if [ "$DRY_RUN" = "true" ]; then
    warn "Running in DRY RUN mode."
  fi
  echo ""

  verify_credentials
  echo ""
  verify_cluster
  echo ""
  update_kubeconfig
  echo ""
  set_default_namespace
  verify_connection

  echo ""
  success "EKS kubeconfig setup complete."
  echo ""
}

main "$@"
