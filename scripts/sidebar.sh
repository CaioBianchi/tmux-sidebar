#!/usr/bin/env bash
#
# Create / destroy the sidebar pane.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

CMD="${1:-create}"
POSITION="${2:-$(get_position)}"

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

  local size
  size="$(get_option "@sidebar-width" "25")"

  local split_args
  case "$position" in
    left)   split_args="-hb -l ${size}" ;;
    right)  split_args="-h  -l ${size}" ;;
  esac

  # Read native status-bar theming.
  local bg fg
  bg="$(get_status_bg)"
  fg="$(get_status_fg)"
  [ -z "$bg" ] && bg="default"
  [ -z "$fg" ] && fg="default"

  # Sidebar theming options.
  local accent_color
  accent_color="$(get_option "@sidebar-accent-color" "default")"

  # Create the sidebar pane without stealing focus (-d).
  local pane_id
  pane_id="$(tmux split-window -d $split_args -P -F '#{pane_id}' \
    "bash '$CURRENT_DIR/render.sh'")"

  # Tag it and record position.
  tmux set-option -p -t "$pane_id" "@sidebar-pane" "1"
  tmux set-option -p -t "$pane_id" "@sidebar-position" "$position"
  tmux set-option -gq "@sidebar-position" "$position"

  # Apply native status-bar colours to the pane.
  tmux select-pane -t "$pane_id" -P "bg=$bg,fg=$fg" >/dev/null 2>&1 || true

  # Pass accent colour into the pane so render.sh can read it.
  tmux set-option -p -t "$pane_id" "@sidebar-accent" "$accent_color"
}

# ─── Main ──────────────────────────────────────────────────────────

case "$CMD" in
  create)
    case "$POSITION" in
      left|right)
        if is_sidebar_present; then
          destroy_sidebar
        fi
        create_pane_sidebar "$POSITION"
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
