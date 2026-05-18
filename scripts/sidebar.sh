#!/usr/bin/env bash
#
# Create / destroy the sidebar pane.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

CMD="${1:-create}"
POSITION="${2:-$(get_position)}"
STATE="${3:-$(get_state)}"

# ─── Destroy ───────────────────────────────────────────────────────

destroy_sidebar() {
  local sidebar_id
  sidebar_id="$(get_sidebar_pane_id)"
  if [ -n "$sidebar_id" ]; then
    tmux kill-pane -t "$sidebar_id" >/dev/null 2>&1 || true
  fi
}

# ─── Create helpers ────────────────────────────────────────────────

create_pane_sidebar() {
  local position="$1"
  local state="$2"

  local size
  if [ "$position" = "left" ] || [ "$position" = "right" ]; then
    if [ "$state" = "expanded" ]; then
      size="$(get_option "@sidebar-width" "25")"
    else
      size="$(get_option "@sidebar-collapsed-width" "4")"
    fi
  else
    if [ "$state" = "expanded" ]; then
      size="$(get_option "@sidebar-height" "3")"
    else
      size="$(get_option "@sidebar-collapsed-height" "1")"
    fi
  fi

  local split_args
  case "$position" in
    left)   split_args="-hb -l ${size}" ;;
    right)  split_args="-h  -l ${size}" ;;
    top)    split_args="-vb -l ${size}" ;;
    bottom) split_args="-v  -l ${size}" ;;
  esac

  # Read native status-bar theming.
  local bg fg
  bg="$(get_status_bg)"
  fg="$(get_status_fg)"
  [ -z "$bg" ] && bg="default"
  [ -z "$fg" ] && fg="default"

  # Create the sidebar pane without stealing focus (-d).
  local pane_id
  pane_id="$(tmux split-window -d $split_args -P -F '#{pane_id}' "bash '$CURRENT_DIR/render.sh'")"

  # Tag it and record state / position.
  tmux set-option -p -t "$pane_id" "@sidebar-pane" "1"
  tmux set-option -p -t "$pane_id" "@sidebar-position" "$position"
  tmux set-option -gq "@sidebar-state" "$state"
  tmux set-option -gq "@sidebar-position" "$position"

  # Apply native status-bar colours to the pane.
  tmux select-pane -t "$pane_id" -P "bg=$bg,fg=$fg" >/dev/null 2>&1 || true
}

# ─── Main ──────────────────────────────────────────────────────────

case "$CMD" in
  create)
    case "$POSITION" in
      left|right|top|bottom)
        if is_sidebar_present; then
          destroy_sidebar
        fi
        create_pane_sidebar "$POSITION" "$STATE"
        ;;
      *)
        echo "tmux-sidebar: invalid position '$POSITION'" >&2
        exit 1
        ;;
    esac
    ;;
  destroy)
    destroy_sidebar
    ;;
  *)
    echo "tmux-sidebar: invalid command '$CMD'" >&2
    exit 1
    ;;
esac
