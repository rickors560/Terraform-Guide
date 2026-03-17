#!/usr/bin/env bash
###############################################################################
# cost-estimate.sh — Run Infracost cost estimation for a Terraform environment
#
# Generates a cost breakdown and optional HTML report for the specified
# environment using Infracost.
#
# Usage:
#   ./scripts/cost-estimate.sh --env <environment> [OPTIONS]
#
# Options:
#   --env ENV          Environment to estimate (dev, staging, prod) [required]
#   --format FORMAT    Output format: table, json, html (default: table)
#   --output FILE      Write report to file (used with --format html/json)
#   --compare FILE     Compare against a previous Infracost JSON baseline
#   --sync-usage FILE  Path to infracost-usage.yml for usage-based estimates
#   --help             Show this help message
#
# Prerequisites:
#   - infracost CLI installed (https://www.infracost.io/docs/)
#   - INFRACOST_API_KEY environment variable set
###############################################################################
set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

ENVIRONMENT=""
FORMAT="table"
OUTPUT_FILE=""
COMPARE_FILE=""
USAGE_FILE=""

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
    --env)        ENVIRONMENT="$2"; shift 2 ;;
    --format)     FORMAT="$2"; shift 2 ;;
    --output)     OUTPUT_FILE="$2"; shift 2 ;;
    --compare)    COMPARE_FILE="$2"; shift 2 ;;
    --sync-usage) USAGE_FILE="$2"; shift 2 ;;
    --help|-h)    usage ;;
    *)            die "Unknown option: $1. Use --help for usage." ;;
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

case "$FORMAT" in
  table|json|html) ;;
  *) die "Invalid format: $FORMAT. Must be one of: table, json, html" ;;
esac

ENV_DIR="$REPO_ROOT/environments/$ENVIRONMENT"
if [ ! -d "$ENV_DIR" ]; then
  die "Environment directory not found: $ENV_DIR"
fi

if ! command -v infracost >/dev/null 2>&1; then
  die "infracost is not installed. Install it from https://www.infracost.io/docs/"
fi

if [ -z "${INFRACOST_API_KEY:-}" ]; then
  die "INFRACOST_API_KEY environment variable is not set. Get a free key at https://www.infracost.io/"
fi

# ---------------------------------------------------------------------------
# Set default output file for HTML
# ---------------------------------------------------------------------------
if [ "$FORMAT" = "html" ] && [ -z "$OUTPUT_FILE" ]; then
  OUTPUT_FILE="$REPO_ROOT/cost-report-${ENVIRONMENT}.html"
fi

if [ "$FORMAT" = "json" ] && [ -z "$OUTPUT_FILE" ]; then
  OUTPUT_FILE="$REPO_ROOT/cost-report-${ENVIRONMENT}.json"
fi

# ---------------------------------------------------------------------------
# Run cost estimation
# ---------------------------------------------------------------------------
main() {
  echo ""
  info "============================================"
  info "  Infracost Cost Estimate"
  info "============================================"
  echo ""
  info "Environment: $ENVIRONMENT"
  info "Directory:   $ENV_DIR"
  info "Format:      $FORMAT"
  if [ -n "$OUTPUT_FILE" ]; then
    info "Output file: $OUTPUT_FILE"
  fi
  echo ""

  # Build the infracost command
  local cmd="infracost breakdown --path $ENV_DIR"

  if [ -n "$USAGE_FILE" ]; then
    if [ ! -f "$USAGE_FILE" ]; then
      die "Usage file not found: $USAGE_FILE"
    fi
    cmd="$cmd --usage-file $USAGE_FILE"
  fi

  # If comparing, generate a diff instead
  if [ -n "$COMPARE_FILE" ]; then
    if [ ! -f "$COMPARE_FILE" ]; then
      die "Comparison file not found: $COMPARE_FILE"
    fi
    info "Generating cost diff against: $COMPARE_FILE"
    echo ""

    case "$FORMAT" in
      table)
        infracost diff --path "$ENV_DIR" --compare-to "$COMPARE_FILE" --format table
        ;;
      json)
        infracost diff --path "$ENV_DIR" --compare-to "$COMPARE_FILE" --format json --out-file "$OUTPUT_FILE"
        success "JSON diff report written to $OUTPUT_FILE"
        ;;
      html)
        infracost diff --path "$ENV_DIR" --compare-to "$COMPARE_FILE" --format html --out-file "$OUTPUT_FILE"
        success "HTML diff report written to $OUTPUT_FILE"
        ;;
    esac
    return
  fi

  # Generate breakdown
  case "$FORMAT" in
    table)
      infracost breakdown --path "$ENV_DIR" --format table
      ;;
    json)
      infracost breakdown --path "$ENV_DIR" --format json --out-file "$OUTPUT_FILE"
      success "JSON report written to $OUTPUT_FILE"
      # Also print summary to terminal
      echo ""
      info "Summary:"
      infracost breakdown --path "$ENV_DIR" --format table 2>/dev/null | tail -10
      ;;
    html)
      # First generate JSON for the HTML output
      local tmp_json
      tmp_json=$(mktemp /tmp/infracost-XXXXXX.json)
      infracost breakdown --path "$ENV_DIR" --format json --out-file "$tmp_json"
      infracost output --path "$tmp_json" --format html --out-file "$OUTPUT_FILE"
      rm -f "$tmp_json"
      success "HTML report written to $OUTPUT_FILE"
      # Print summary to terminal
      echo ""
      info "Summary:"
      infracost breakdown --path "$ENV_DIR" --format table 2>/dev/null | tail -10
      ;;
  esac

  echo ""
  success "Cost estimation complete for $ENVIRONMENT."
}

main "$@"
