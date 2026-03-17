#!/usr/bin/env bash
###############################################################################
# generate-docs.sh — Auto-generate Terraform module documentation
#
# Scans all modules for *.tf files, runs terraform-docs to produce input/output
# tables, and inserts the generated markdown between marker comments in each
# module's README.md. Creates a README.md if one does not exist.
#
# Usage:
#   ./scripts/generate-docs.sh [OPTIONS]
#
# Options:
#   --module PATH     Generate docs for a single module directory
#   --config FILE     Path to terraform-docs config file
#   --check           Exit with non-zero if any README would change (CI mode)
#   --help            Show this help message
#
# Marker format in README.md:
#   <!-- BEGIN_TF_DOCS -->
#   ... generated content ...
#   <!-- END_TF_DOCS -->
###############################################################################
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly BEGIN_MARKER="<!-- BEGIN_TF_DOCS -->"
readonly END_MARKER="<!-- END_TF_DOCS -->"

SINGLE_MODULE=""
CONFIG_FILE=""
CHECK_MODE=false

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
  sed -n '/^# Usage:/,/^# Marker/p' "$0" | head -n -1 | sed 's/^# //' | sed 's/^#//'
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --module)  SINGLE_MODULE="$2"; shift 2 ;;
    --config)  CONFIG_FILE="$2"; shift 2 ;;
    --check)   CHECK_MODE=true; shift ;;
    --help|-h) usage ;;
    *)         die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ---------------------------------------------------------------------------
# Prerequisites
# ---------------------------------------------------------------------------
if ! command -v terraform-docs >/dev/null 2>&1; then
  die "terraform-docs is not installed. Run ./scripts/setup.sh first."
fi

# ---------------------------------------------------------------------------
# Find module directories
# ---------------------------------------------------------------------------
find_modules() {
  if [ -n "$SINGLE_MODULE" ]; then
    if [ ! -d "$SINGLE_MODULE" ]; then
      die "Module directory not found: $SINGLE_MODULE"
    fi
    echo "$SINGLE_MODULE"
    return
  fi

  # Search under modules/, components/, environments/ for directories with .tf files
  local search_dirs=("$REPO_ROOT/modules" "$REPO_ROOT/components" "$REPO_ROOT/environments")
  for search_dir in "${search_dirs[@]}"; do
    if [ -d "$search_dir" ]; then
      find "$search_dir" -type f -name "*.tf" -exec dirname {} \; | sort -u
    fi
  done
}

# ---------------------------------------------------------------------------
# Generate docs for a single module
# ---------------------------------------------------------------------------
generate_for_module() {
  local module_dir="$1"
  local readme="$module_dir/README.md"
  local relative_path="${module_dir#"$REPO_ROOT/"}"

  # Build terraform-docs command
  local tfdocs_cmd="terraform-docs markdown table"
  if [ -n "$CONFIG_FILE" ]; then
    tfdocs_cmd="$tfdocs_cmd --config $CONFIG_FILE"
  fi
  tfdocs_cmd="$tfdocs_cmd $module_dir"

  # Generate the documentation content
  local generated
  generated=$(eval "$tfdocs_cmd" 2>/dev/null) || {
    warn "terraform-docs failed for $relative_path; skipping"
    return 0
  }

  # If no content was generated (no variables/outputs), skip
  if [ -z "$generated" ]; then
    info "No inputs/outputs found in $relative_path; skipping"
    return 0
  fi

  # Create README.md with markers if it does not exist
  if [ ! -f "$readme" ]; then
    local module_name
    module_name=$(basename "$module_dir")
    cat > "$readme" <<SCAFFOLD_EOF
# $module_name

$BEGIN_MARKER
$END_MARKER
SCAFFOLD_EOF
    info "Created $relative_path/README.md"
  fi

  # Ensure markers exist in the README
  if ! grep -qF "$BEGIN_MARKER" "$readme"; then
    printf '\n%s\n%s\n' "$BEGIN_MARKER" "$END_MARKER" >> "$readme"
  fi

  # Replace content between markers
  local new_content
  new_content=$(awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" -v content="$generated" '
    $0 ~ begin { print; print content; found=1; next }
    found && $0 ~ end { found=0 }
    !found { print }
  ' "$readme")

  if [ "$CHECK_MODE" = "true" ]; then
    if ! diff -q <(echo "$new_content") "$readme" >/dev/null 2>&1; then
      warn "README.md is out of date: $relative_path"
      return 1
    fi
    success "$relative_path: up to date"
    return 0
  fi

  echo "$new_content" > "$readme"
  success "Updated $relative_path/README.md"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  info "============================================"
  info "  Terraform Documentation Generator"
  info "============================================"
  echo ""

  local modules
  modules=$(find_modules)

  if [ -z "$modules" ]; then
    warn "No Terraform modules found."
    exit 0
  fi

  local total=0
  local updated=0
  local failed=0

  while IFS= read -r module_dir; do
    total=$((total + 1))
    if generate_for_module "$module_dir"; then
      updated=$((updated + 1))
    else
      failed=$((failed + 1))
    fi
  done <<< "$modules"

  echo ""
  info "Processed $total module(s): $updated succeeded, $failed need updates"

  if [ "$CHECK_MODE" = "true" ] && [ "$failed" -gt 0 ]; then
    echo ""
    error "$failed README(s) are out of date. Run './scripts/generate-docs.sh' to update."
    exit 1
  fi

  echo ""
  success "Documentation generation complete."
}

main "$@"
