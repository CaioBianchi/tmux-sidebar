#!/usr/bin/env bash
#
# Integration tests for cycle.sh (position rotation).
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

# ── Start on right and cycle through all positions ─────────────────

bash "$PROJECT_DIR/scripts/sidebar.sh" create right collapsed >/dev/null 2>&1 || true
sleep 0.5

assert_equals "right" "$(get_position)" "initial position is right"

# Cycle once → top
bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5

assert_equals "top" "$(get_position)" "cycle right → top"
assert_true "[ -n \"\$(get_sidebar_pane_id)\" ]" "sidebar still present after cycling to top"

# Cycle twice more → bottom
tmux set-option -gq "@sidebar-position" "top"
bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5
assert_equals "bottom" "$(get_position)" "cycle top → bottom"

# Cycle again → left
tmux set-option -gq "@sidebar-position" "bottom"
bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5
assert_equals "left" "$(get_position)" "cycle bottom → left"

# Final cycle → back to right
tmux set-option -gq "@sidebar-position" "left"
bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5
assert_equals "right" "$(get_position)" "cycle left → right (full loop)"

# ── State preservation while cycling ──────────────────────────────

# Expand then cycle.
tmux set-option -gq "@sidebar-state" "collapsed"
bash "$PROJECT_DIR/scripts/sidebar.sh" create right collapsed >/dev/null 2>&1 || true
sleep 0.5

bash "$PROJECT_DIR/scripts/toggle.sh" >/dev/null 2>&1 || true
sleep 0.3
assert_equals "expanded" "$(get_state)" "state is expanded before cycle"

bash "$PROJECT_DIR/scripts/cycle.sh" >/dev/null 2>&1 || true
sleep 0.5
assert_equals "expanded" "$(get_state)" "state preserved during cycle"

teardown_tmux_session "$SESSION"
cleanup_test_server
summary
