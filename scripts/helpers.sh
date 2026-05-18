#!/usr/bin/env bash
#
# Helper functions for tmux-sidebar
#

set -euo pipefail

get_option() {
  local option="$1"
  local default_value="$2"
  local value
  value="$(tmux show-option -gqv "$option" 2>/dev/null || true)"
  if [ -z "$value" ]; then
    echo "$default_value"
  else
    echo "$value"
  fi
}

set_state() {
  tmux set-option -gq "@sidebar-state" "$1"
}

get_state() {
  get_option "@sidebar-state" "collapsed"
}

get_position() {
  get_option "@sidebar-position" "right"
}

set_position() {
  tmux set-option -gq "@sidebar-position" "$1"
}

# Extract an attribute value from a tmux style string.
# Example: style="bg=colour235 fg=colour250"
#          extract_color "$style" "bg"  → "colour235"
extract_color() {
  local style="$1"
  local attr="$2"
  local value=""
  # Try "attr=value" bounded by spaces or string ends
  value="$(echo "$style" | grep -oE "(^| )${attr}=[^ ]+" | head -1 | cut -d= -f2)"
  echo "$value"
}

get_status_style() {
  tmux show-option -gqv "status-style" 2>/dev/null || true
}

get_status_bg() {
  local style
  style="$(get_status_style)"
  extract_color "$style" "bg"
}

get_status_fg() {
  local style
  style="$(get_status_style)"
  extract_color "$style" "fg"
}

# Return the pane ID of the sidebar in the current window, or empty string.
get_sidebar_pane_id() {
  local pane_id
  for pane_id in $(tmux list-panes -F '#{pane_id}' 2>/dev/null); do
    if [ "$(tmux display-message -p -t "$pane_id" '#{@sidebar-pane}' 2>/dev/null)" = "1" ]; then
      echo "$pane_id"
      return 0
    fi
  done
  echo ""
  return 1
}

# Return 0 if a sidebar pane exists in the current window.
is_sidebar_present() {
  get_sidebar_pane_id >/dev/null 2>&1
}

# Return the first non-sidebar pane ID in the current window.
get_main_pane_id() {
  local pane_id
  for pane_id in $(tmux list-panes -F '#{pane_id}' 2>/dev/null); do
    if [ "$(tmux display-message -p -t "$pane_id" '#{@sidebar-pane}' 2>/dev/null)" != "1" ]; then
      echo "$pane_id"
      return 0
    fi
  done
  echo ""
  return 1
}
