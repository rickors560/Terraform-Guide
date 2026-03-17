#!/usr/bin/env bash
###############################################################################
# setup.sh — Development environment setup
#
# Checks for and installs required tools: Terraform, AWS CLI, kubectl, helm,
# tflint, terraform-docs, pre-commit, checkov, and docker. Verifies versions
# and configures pre-commit hooks.
#
# Usage:
#   ./scripts/setup.sh [--skip-install] [--help]
#
# Options:
#   --skip-install   Only verify tools, do not attempt to install missing ones
#   --help           Show this help message
###############################################################################
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly TERRAFORM_VERSION="1.7.5"
readonly TFLINT_VERSION="0.50.3"
readonly TERRAFORM_DOCS_VERSION="0.17.0"

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SKIP_INSTALL=false

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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
info()    { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
success() { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()    { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
error()   { printf "${RED}[ERROR]${NC} %s\n" "$*" >&2; }
die()     { error "$@"; exit 1; }

usage() {
  sed -n '/^# Usage:/,/^###/p' "$0" | head -n -1 | sed 's/^# //' | sed 's/^#//'
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --skip-install) SKIP_INSTALL=true; shift ;;
    --help|-h)      usage ;;
    *)              die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------
detect_os() {
  case "$(uname -s)" in
    Linux*)  OS="linux" ;;
    Darwin*) OS="darwin" ;;
    *)       die "Unsupported operating system: $(uname -s)" ;;
  esac

  case "$(uname -m)" in
    x86_64|amd64)  ARCH="amd64" ;;
    aarch64|arm64) ARCH="arm64" ;;
    *)             die "Unsupported architecture: $(uname -m)" ;;
  esac

  info "Detected OS=$OS ARCH=$ARCH"
}

# ---------------------------------------------------------------------------
# Tool check / install functions
# ---------------------------------------------------------------------------
check_command() {
  command -v "$1" >/dev/null 2>&1
}

install_terraform() {
  info "Installing Terraform $TERRAFORM_VERSION..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  local zip_file="$tmp_dir/terraform.zip"
  curl -sL "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_${OS}_${ARCH}.zip" -o "$zip_file"
  unzip -qo "$zip_file" -d "$tmp_dir"
  sudo mv "$tmp_dir/terraform" /usr/local/bin/terraform
  rm -rf "$tmp_dir"
  success "Terraform $TERRAFORM_VERSION installed"
}

install_awscli() {
  info "Installing AWS CLI v2..."
  local tmp_dir
  tmp_dir=$(mktemp -d)
  if [ "$OS" = "linux" ]; then
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "$tmp_dir/awscliv2.zip"
    unzip -qo "$tmp_dir/awscliv2.zip" -d "$tmp_dir"
    sudo "$tmp_dir/aws/install" --update
  elif [ "$OS" = "darwin" ]; then
    curl -sL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "$tmp_dir/AWSCLIV2.pkg"
    sudo installer -pkg "$tmp_dir/AWSCLIV2.pkg" -target /
  fi
  rm -rf "$tmp_dir"
  success "AWS CLI installed"
}

install_kubectl() {
  info "Installing kubectl..."
  local version
  version=$(curl -sL https://dl.k8s.io/release/stable.txt)
  curl -sL "https://dl.k8s.io/release/${version}/bin/${OS}/${ARCH}/kubectl" -o /tmp/kubectl
  chmod +x /tmp/kubectl
  sudo mv /tmp/kubectl /usr/local/bin/kubectl
  success "kubectl installed"
}

install_helm() {
  info "Installing Helm..."
  curl -sL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  success "Helm installed"
}

install_tflint() {
  info "Installing TFLint $TFLINT_VERSION..."
  curl -sL "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_${OS}_${ARCH}.zip" -o /tmp/tflint.zip
  unzip -qo /tmp/tflint.zip -d /tmp
  sudo mv /tmp/tflint /usr/local/bin/tflint
  rm -f /tmp/tflint.zip
  success "TFLint $TFLINT_VERSION installed"
}

install_terraform_docs() {
  info "Installing terraform-docs $TERRAFORM_DOCS_VERSION..."
  local binary="terraform-docs-v${TERRAFORM_DOCS_VERSION}-${OS}-${ARCH}"
  if [ "$OS" = "darwin" ] || [ "$OS" = "linux" ]; then
    curl -sL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-${OS}-${ARCH}.tar.gz" -o /tmp/terraform-docs.tar.gz
    tar -xzf /tmp/terraform-docs.tar.gz -C /tmp terraform-docs
    sudo mv /tmp/terraform-docs /usr/local/bin/terraform-docs
    rm -f /tmp/terraform-docs.tar.gz
  fi
  success "terraform-docs $TERRAFORM_DOCS_VERSION installed"
}

install_precommit() {
  info "Installing pre-commit..."
  if check_command pip3; then
    pip3 install --user pre-commit
  elif check_command pip; then
    pip install --user pre-commit
  elif check_command brew; then
    brew install pre-commit
  else
    die "Cannot install pre-commit: pip3, pip, and brew are all missing"
  fi
  success "pre-commit installed"
}

install_checkov() {
  info "Installing checkov..."
  if check_command pip3; then
    pip3 install --user checkov
  elif check_command pip; then
    pip install --user checkov
  else
    die "Cannot install checkov: pip3 and pip are both missing"
  fi
  success "checkov installed"
}

# ---------------------------------------------------------------------------
# Verify and optionally install each tool
# ---------------------------------------------------------------------------
ensure_tool() {
  local name="$1"
  local install_fn="$2"

  if check_command "$name"; then
    local ver
    case "$name" in
      terraform)      ver=$(terraform version -json 2>/dev/null | grep -o '"terraform_version":"[^"]*"' | cut -d'"' -f4 || terraform version | head -1) ;;
      aws)            ver=$(aws --version 2>&1 | awk '{print $1}') ;;
      kubectl)        ver=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>&1 | head -1) ;;
      helm)           ver=$(helm version --short 2>/dev/null || echo "unknown") ;;
      tflint)         ver=$(tflint --version 2>/dev/null | head -1) ;;
      terraform-docs) ver=$(terraform-docs version 2>/dev/null) ;;
      pre-commit)     ver=$(pre-commit --version 2>/dev/null) ;;
      checkov)        ver=$(checkov --version 2>/dev/null) ;;
      docker)         ver=$(docker --version 2>/dev/null) ;;
      *)              ver="installed" ;;
    esac
    success "$name: $ver"
  else
    if [ "$SKIP_INSTALL" = "true" ]; then
      warn "$name: NOT FOUND (install skipped via --skip-install)"
      return 1
    fi
    warn "$name: not found, attempting install..."
    "$install_fn"
  fi
  return 0
}

# ---------------------------------------------------------------------------
# Configure pre-commit hooks
# ---------------------------------------------------------------------------
setup_precommit_hooks() {
  info "Configuring pre-commit hooks..."

  if [ ! -f "$REPO_ROOT/.pre-commit-config.yaml" ]; then
    cat > "$REPO_ROOT/.pre-commit-config.yaml" <<'PRECOMMIT_EOF'
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
        args: ['--allow-multiple-documents']
      - id: check-json
      - id: check-merge-conflict
      - id: detect-private-key
      - id: no-commit-to-branch
        args: ['--branch', 'main']

  - repo: https://github.com/antonbabenko/pre-commit-terraform
    rev: v1.86.0
    hooks:
      - id: terraform_fmt
      - id: terraform_validate
        args:
          - --hook-config=--retry-once-with-cleanup=true
      - id: terraform_tflint
        args:
          - --args=--config=__GIT_WORKING_DIR__/.tflint.hcl
      - id: terraform_docs
        args:
          - --args=--config=.terraform-docs.yml

  - repo: https://github.com/bridgecrewio/checkov
    rev: 3.2.0
    hooks:
      - id: checkov
        args: ['--quiet', '--soft-fail']
PRECOMMIT_EOF
    success "Created .pre-commit-config.yaml"
  else
    info ".pre-commit-config.yaml already exists"
  fi

  if check_command pre-commit; then
    cd "$REPO_ROOT"
    pre-commit install
    success "pre-commit hooks installed in .git/hooks"
  else
    warn "pre-commit not available; skipping hook installation"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  info "============================================"
  info "  Development Environment Setup"
  info "============================================"
  echo ""

  detect_os

  local failed=0

  echo ""
  info "Checking required tools..."
  echo ""

  ensure_tool "terraform"      install_terraform      || failed=$((failed + 1))
  ensure_tool "aws"            install_awscli         || failed=$((failed + 1))
  ensure_tool "kubectl"        install_kubectl        || failed=$((failed + 1))
  ensure_tool "helm"           install_helm           || failed=$((failed + 1))
  ensure_tool "tflint"         install_tflint         || failed=$((failed + 1))
  ensure_tool "terraform-docs" install_terraform_docs || failed=$((failed + 1))
  ensure_tool "pre-commit"     install_precommit      || failed=$((failed + 1))
  ensure_tool "checkov"        install_checkov        || failed=$((failed + 1))
  ensure_tool "docker"         install_docker_stub    || failed=$((failed + 1))

  echo ""
  setup_precommit_hooks
  echo ""

  if [ "$failed" -gt 0 ]; then
    warn "$failed tool(s) could not be found or installed."
    warn "Install them manually and re-run this script."
    exit 1
  fi

  echo ""
  success "============================================"
  success "  All tools verified. Environment is ready."
  success "============================================"
  echo ""
}

install_docker_stub() {
  warn "Docker must be installed manually."
  warn "  Linux:  https://docs.docker.com/engine/install/"
  warn "  macOS:  https://docs.docker.com/desktop/install/mac-install/"
  return 1
}

main "$@"
