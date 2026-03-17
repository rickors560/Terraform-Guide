#!/usr/bin/env bash
###############################################################################
# cleanup.sh — Clean up Terraform artifacts from the repository
#
# Removes .terraform directories, .terraform.lock.hcl files, plan output
# files, crash logs, and other generated artifacts. Supports a dry-run mode
# to preview what would be deleted.
#
# Usage:
#   ./scripts/cleanup.sh [OPTIONS]
#
# Options:
#   --dry-run        Show what would be deleted without deleting
#   --keep-locks     Keep .terraform.lock.hcl files (they are committed)
#   --all            Also remove cost reports and generated docs
#   --help           Show this help message
###############################################################################
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=false
KEEP_LOCKS=false
CLEAN_ALL=false

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
  sed -n '/^# Usage:/,/^###/p' "$0" | head -n -1 | sed 's/^# //' | sed 's/^#//'
  exit 0
}

# ---------------------------------------------------------------------------
# Parse arguments
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run)    DRY_RUN=true; shift ;;
    --keep-locks) KEEP_LOCKS=true; shift ;;
    --all)        CLEAN_ALL=true; shift ;;
    --help|-h)    usage ;;
    *)            die "Unknown option: $1. Use --help for usage." ;;
  esac
done

# ---------------------------------------------------------------------------
# Counters
# ---------------------------------------------------------------------------
TOTAL_FOUND=0
TOTAL_SIZE=0

# ---------------------------------------------------------------------------
# Remove helper — respects --dry-run
# ---------------------------------------------------------------------------
remove_item() {
  local path="$1"
  local relative="${path#"$REPO_ROOT/"}"

  if [ -d "$path" ]; then
    local size
    size=$(du -sb "$path" 2>/dev/null | cut -f1 || echo 0)
    TOTAL_SIZE=$((TOTAL_SIZE + size))
  elif [ -f "$path" ]; then
    local size
    size=$(stat -c %s "$path" 2>/dev/null || stat -f %z "$path" 2>/dev/null || echo 0)
    TOTAL_SIZE=$((TOTAL_SIZE + size))
  fi

  TOTAL_FOUND=$((TOTAL_FOUND + 1))

  if [ "$DRY_RUN" = "true" ]; then
    info "[DRY RUN] Would remove: $relative"
  else
    rm -rf "$path"
    success "Removed: $relative"
  fi
}

# ---------------------------------------------------------------------------
# Cleanup functions
# ---------------------------------------------------------------------------
clean_terraform_dirs() {
  info "Scanning for .terraform directories..."
  while IFS= read -r -d '' dir; do
    remove_item "$dir"
  done < <(find "$REPO_ROOT" -type d -name ".terraform" -print0 2>/dev/null)
}

clean_lock_files() {
  if [ "$KEEP_LOCKS" = "true" ]; then
    info "Skipping .terraform.lock.hcl files (--keep-locks)"
    return
  fi
  info "Scanning for .terraform.lock.hcl files..."
  while IFS= read -r -d '' file; do
    remove_item "$file"
  done < <(find "$REPO_ROOT" -type f -name ".terraform.lock.hcl" -print0 2>/dev/null)
}

clean_plan_files() {
  info "Scanning for plan output files..."
  while IFS= read -r -d '' file; do
    remove_item "$file"
  done < <(find "$REPO_ROOT" -type f \( -name "tfplan" -o -name "*.tfplan" -o -name "plan.out" -o -name "plan_output.txt" \) -print0 2>/dev/null)
}

clean_crash_logs() {
  info "Scanning for crash logs..."
  while IFS= read -r -d '' file; do
    remove_item "$file"
  done < <(find "$REPO_ROOT" -type f -name "crash.log" -print0 2>/dev/null)
  while IFS= read -r -d '' file; do
    remove_item "$file"
  done < <(find "$REPO_ROOT" -type f -name "crash.*.log" -print0 2>/dev/null)
}

clean_tfvar_backups() {
  info "Scanning for backup and override files..."
  while IFS= read -r -d '' file; do
    remove_item "$file"
  done < <(find "$REPO_ROOT" -type f \( -name "*.tfvars.bak" -o -name "override.tf" -o -name "override.tf.json" -o -name "*_override.tf" -o -name "*_override.tf.json" \) -print0 2>/dev/null)
}

clean_extra_artifacts() {
  info "Scanning for cost reports and generated artifacts..."

  # Infracost reports
  while IFS= read -r -d '' file; do
    remove_item "$file"
  done < <(find "$REPO_ROOT" -maxdepth 1 -type f \( -name "cost-report-*.html" -o -name "cost-report-*.json" \) -print0 2>/dev/null)

  # SARIF files
  while IFS= read -r -d '' file; do
    remove_item "$file"
  done < <(find "$REPO_ROOT" -maxdepth 1 -type f -name "*.sarif" -print0 2>/dev/null)

  # Drift reports
  if [ -d "$REPO_ROOT/drift-reports" ]; then
    remove_item "$REPO_ROOT/drift-reports"
  fi
}

# ---------------------------------------------------------------------------
# Format size for display
# ---------------------------------------------------------------------------
format_size() {
  local bytes=$1
  if [ "$bytes" -ge 1073741824 ]; then
    echo "$(echo "scale=2; $bytes / 1073741824" | bc) GB"
  elif [ "$bytes" -ge 1048576 ]; then
    echo "$(echo "scale=2; $bytes / 1048576" | bc) MB"
  elif [ "$bytes" -ge 1024 ]; then
    echo "$(echo "scale=2; $bytes / 1024" | bc) KB"
  else
    echo "$bytes bytes"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  echo ""
  info "============================================"
  info "  Terraform Artifact Cleanup"
  info "============================================"
  echo ""

  if [ "$DRY_RUN" = "true" ]; then
    warn "Running in DRY RUN mode. Nothing will be deleted."
    echo ""
  fi

  clean_terraform_dirs
  echo ""
  clean_lock_files
  echo ""
  clean_plan_files
  echo ""
  clean_crash_logs
  echo ""
  clean_tfvar_backups

  if [ "$CLEAN_ALL" = "true" ]; then
    echo ""
    clean_extra_artifacts
  fi

  echo ""
  info "============================================"
  info "  Summary"
  info "============================================"
  echo ""

  if [ "$TOTAL_FOUND" -eq 0 ]; then
    success "No artifacts found. Repository is already clean."
  else
    local size_display
    size_display=$(format_size "$TOTAL_SIZE")
    if [ "$DRY_RUN" = "true" ]; then
      info "Found $TOTAL_FOUND item(s) totaling ~$size_display"
      info "Run without --dry-run to delete them."
    else
      success "Removed $TOTAL_FOUND item(s) totaling ~$size_display"
    fi
  fi
  echo ""
}

main "$@"
