#!/usr/bin/env bash
#
# Integration tests for sidebar creation / destruction.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/framework.sh"
source "$PROJECT_DIR/scripts/helpers.sh"

echo "→ sidebar.sh integration tests"

SESSION="__tmux_sidebar_test_sidebar"

init_test_server
setup_tmux_session "$SESSION"

# ── Create sidebar on the left (default) ──────────────────────────

assert_true "tmux has-session -t $SESSION" "session exists"

bash "$PROJECT_DIR/scripts/sidebar.sh" create left >/dev/null 2>&1 || true
sleep 0.5

assert_true "[ -n \"\$(get_sidebar_pane_id)\" ]" "sidebar pane was created"

SIDEBAR_ID="$(get_sidebar_pane_id)"
assert_contains "$(tmux display-message -p -t "$SIDEBAR_ID" '#{@sidebar-pane}')" \
  "1" \
  "sidebar pane is tagged with @sidebar-pane=1"

assert_contains "$(tmux display-message -p -t "$SIDEBAR_ID" '#{@sidebar-position}')" \
  "left" \
  "sidebar pane has position=left"

# ── Create sidebar on the right (should replace left) ─────────────

bash "$PROJECT_DIR/scripts/sidebar.sh" create right >/dev/null 2>&1 || true
sleep 0.5

assert_contains "$(tmux display-message -p -t "$(get_sidebar_pane_id)" '#{@sidebar-position}')" \
  "right" \
  "sidebar switched to right"

# Count panes – should be exactly 2 (main + sidebar).
PANE_COUNT="$(tmux list-panes -t "$SESSION:test_window" | wc -l | tr -d ' ')"
assert_equals "2" "$PANE_COUNT" "exactly two panes after switching position"

# ── Destroy ────────────────────────────────────────────────────────

# Kill the sidebar pane directly.
SIDEBAR_ID="$(get_sidebar_pane_id)"
[ -n "$SIDEBAR_ID" ] && tmux kill-pane -t "$SIDEBAR_ID" >/dev/null 2>&1 || true
sleep 0.3

PANE_COUNT_AFTER="$(tmux list-panes -t "$SESSION:test_window" | wc -l | tr -d ' ')"
assert_equals "1" "$PANE_COUNT_AFTER" "only main pane remains after destroy"

assert_false "[ -n \"\$(get_sidebar_pane_id)\" ]" "no sidebar pane remains"

teardown_tmux_session "$SESSION"
cleanup_test_server
summary
