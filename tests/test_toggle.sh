#!/usr/bin/env bash
#
# Integration tests for toggle.sh (expand / collapse).
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$SCRIPT_DIR/framework.sh"
source "$PROJECT_DIR/scripts/helpers.sh"

echo "→ toggle.sh integration tests"

SESSION="__tmux_sidebar_test_toggle"

init_test_server
setup_tmux_session "$SESSION"

# ── Toggle right sidebar ───────────────────────────────────────────

bash "$PROJECT_DIR/scripts/sidebar.sh" create right collapsed >/dev/null 2>&1 || true
sleep 0.5

assert_equals "collapsed" "$(get_state)" "initial state is collapsed"

bash "$PROJECT_DIR/scripts/toggle.sh" >/dev/null 2>&1 || true
sleep 0.3

assert_equals "expanded" "$(get_state)" "toggle switches to expanded"

SIDEBAR_ID="$(get_sidebar_pane_id)"
WIDTH="$(tmux display-message -p -t "$SIDEBAR_ID" '#{pane_width}')"
DEFAULT_WIDTH="$(get_option '@sidebar-width' '25')"
assert_equals "$DEFAULT_WIDTH" "$WIDTH" "expanded width matches config"

# Toggle back.
bash "$PROJECT_DIR/scripts/toggle.sh" >/dev/null 2>&1 || true
sleep 0.3

assert_equals "collapsed" "$(get_state)" "toggle switches back to collapsed"

WIDTH_COLLAPSED="$(tmux display-message -p -t "$(get_sidebar_pane_id)" '#{pane_width}')"
DEFAULT_COLLAPSED="$(get_option '@sidebar-collapsed-width' '4')"
assert_equals "$DEFAULT_COLLAPSED" "$WIDTH_COLLAPSED" "collapsed width matches config"

# ── Toggle top sidebar (height) ───────────────────────────────────

bash "$PROJECT_DIR/scripts/sidebar.sh" create top expanded >/dev/null 2>&1 || true
sleep 0.5

assert_equals "expanded" "$(get_state)" "top starts expanded"

bash "$PROJECT_DIR/scripts/toggle.sh" >/dev/null 2>&1 || true
sleep 0.3

assert_equals "collapsed" "$(get_state)" "top toggles to collapsed"

HEIGHT_COLLAPSED="$(tmux display-message -p -t "$(get_sidebar_pane_id)" '#{pane_height}')"
DEFAULT_H_COLLAPSED="$(get_option '@sidebar-collapsed-height' '1')"
assert_equals "$DEFAULT_H_COLLAPSED" "$HEIGHT_COLLAPSED" "collapsed height matches config"

# Toggle back.
bash "$PROJECT_DIR/scripts/toggle.sh" >/dev/null 2>&1 || true
sleep 0.3

HEIGHT_EXPANDED="$(tmux display-message -p -t "$(get_sidebar_pane_id)" '#{pane_height}')"
DEFAULT_H="$(get_option '@sidebar-height' '3')"
assert_equals "$DEFAULT_H" "$HEIGHT_EXPANDED" "expanded height matches config"

teardown_tmux_session "$SESSION"
cleanup_test_server
summary
