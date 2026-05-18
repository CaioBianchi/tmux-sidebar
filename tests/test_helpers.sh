#!/usr/bin/env bash
#
# Unit tests for helpers.sh
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/framework.sh"
source "$PROJECT_DIR/scripts/helpers.sh"

echo "→ helpers.sh unit tests"

init_test_server

# ── extract_color ───────────────────────────────────────────────────

assert_equals "colour235" \
  "$(extract_color "bg=colour235 fg=colour250" "bg")" \
  "extract_color finds bg"

assert_equals "colour250" \
  "$(extract_color "bg=colour235 fg=colour250" "fg")" \
  "extract_color finds fg"

assert_equals "" \
  "$(extract_color "bg=colour235" "fg")" \
  "extract_color returns empty for missing attr"

assert_equals "green" \
  "$(extract_color "bg=green fg=black" "bg")" \
  "extract_color works with named colours"

assert_equals "#1a1a1a" \
  "$(extract_color "bg=#1a1a1a" "bg")" \
  "extract_color works with hex colours"

# ── get_option (with a mock tmux option) ────────────────────────────

tmux set-option -gq "@test-option-42" "hello-world"
assert_equals "hello-world" \
  "$(get_option "@test-option-42" "default")" \
  "get_option reads existing tmux option"

assert_equals "fallback" \
  "$(get_option "@nonexistent-option-xyz" "fallback")" \
  "get_option returns default when option unset"

# Clean up
tmux set-option -gu "@test-option-42" 2>/dev/null || true

cleanup_test_server
summary
