#!/usr/bin/env bash
#
# Integration tests for cycle.sh (position toggle between left/right).
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/framework.sh"
source "$PROJECT_DIR/scripts/helpers.sh"

echo "→ cycle.sh integration tests"

SESSION="__tmux_sidebar_test_cycle"

init_test_server
setup_tmux_session "$SESSION"

# ── Start on left and cycle to right ──────────────────────────────

bash "$PROJECT_DIR/scripts/sidebar.sh" create left >/dev/null 2>&1 || true
sleep 0.5

assert_equals "left" "$(get_position)" "initial position is left"

# Cycle once → right
bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5

assert_equals "right" "$(get_position)" "cycle left → right"
assert_true "[ -n \"\$(get_sidebar_pane_id)\" ]" "sidebar still present after cycling to right"

# Cycle again → back to left
tmux set-option -gq "@sidebar-position" "right"
bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5
assert_equals "left" "$(get_position)" "cycle right → left"

# Full loop → back to right
tmux set-option -gq "@sidebar-position" "left"
bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5
assert_equals "right" "$(get_position)" "cycle left → right (full loop)"

teardown_tmux_session "$SESSION"
cleanup_test_server
summary
