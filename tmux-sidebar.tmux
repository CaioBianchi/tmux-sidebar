#!/usr/bin/env bash
#
# tmux-sidebar
# A tmux plugin for side status bars with expand/collapse support.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Defaults ──────────────────────────────────────────────────────

sidebar_default_position="right"
sidebar_default_state="collapsed"
sidebar_default_enabled="0"
sidebar_default_width="25"
sidebar_default_collapsed_width="4"
sidebar_default_height="3"
sidebar_default_collapsed_height="1"
sidebar_default_key="b"
sidebar_default_toggle_key="B"
sidebar_default_refresh_interval="5"

set_default() {
  local option="$1"
  local default_value="$2"
  local current_value
  current_value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
  if [ -z "$current_value" ]; then
    tmux set-option -gq "$option" "$default_value"
  fi
}

set_default "@sidebar-position"    "$sidebar_default_position"
set_default "@sidebar-state"       "$sidebar_default_state"
set_default "@sidebar-enabled"     "$sidebar_default_enabled"
set_default "@sidebar-width"        "$sidebar_default_width"
set_default "@sidebar-collapsed-width" "$sidebar_default_collapsed_width"
set_default "@sidebar-height"       "$sidebar_default_height"
set_default "@sidebar-collapsed-height" "$sidebar_default_collapsed_height"
set_default "@sidebar-key"          "$sidebar_default_key"
set_default "@sidebar-toggle-key"   "$sidebar_default_toggle_key"
set_default "@sidebar-refresh-interval" "$sidebar_default_refresh_interval"

# ─── Key bindings ──────────────────────────────────────────────────

tmux bind-key "$(tmux show-option -gqv "@sidebar-key")" \
  run-shell "$CURRENT_DIR/scripts/cycle.sh"

tmux bind-key "$(tmux show-option -gqv "@sidebar-toggle-key")" \
  run-shell "$CURRENT_DIR/scripts/toggle.sh"

# ─── Auto-start ────────────────────────────────────────────────────

if [ "$(tmux show-option -gqv "@sidebar-enabled")" = "1" ]; then
  "$CURRENT_DIR/scripts/sidebar.sh" create >/dev/null 2>&1 || true
fi
