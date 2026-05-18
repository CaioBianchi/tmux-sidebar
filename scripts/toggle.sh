#!/usr/bin/env bash
#
# Toggle the sidebar between expanded and collapsed.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

POSITION="$(get_position)"
CURRENT_STATE="$(get_state)"

# Flip state.
if [ "$CURRENT_STATE" = "expanded" ]; then
  NEW_STATE="collapsed"
else
  NEW_STATE="expanded"
fi

set_state "$NEW_STATE"

# Resize existing sidebar if there is one.
SIDEBAR_ID="$(get_sidebar_pane_id)"
if [ -n "$SIDEBAR_ID" ]; then
  case "$POSITION" in
    left|right)
      new_size=""
      if [ "$NEW_STATE" = "expanded" ]; then
        new_size="$(get_option "@sidebar-width" "25")"
      else
        new_size="$(get_option "@sidebar-collapsed-width" "4")"
      fi
      tmux resize-pane -t "$SIDEBAR_ID" -x "$new_size"
      ;;
    top|bottom)
      new_size=""
      if [ "$NEW_STATE" = "expanded" ]; then
        new_size="$(get_option "@sidebar-height" "3")"
      else
        new_size="$(get_option "@sidebar-collapsed-height" "1")"
      fi
      tmux resize-pane -t "$SIDEBAR_ID" -y "$new_size"
      ;;
  esac
fi
