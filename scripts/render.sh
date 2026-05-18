#!/usr/bin/env bash
#
# Render loop that runs inside the sidebar pane.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

REFRESH_INTERVAL="$(get_option "@sidebar-refresh-interval" "5")"

# ─── Helpers ───────────────────────────────────────────────────────

# Print text, truncating or padding to exactly $width characters.
fit_width() {
  local text="$1"
  local width="$2"
  local len="${#text}"
  if [ "$len" -gt "$width" ]; then
    echo "${text:0:$width}"
  else
    printf "%-${width}s" "$text"
  fi
}

# ─── Main loop ─────────────────────────────────────────────────────

while true; do
  # Reload state / position every iteration so external changes are picked up.
  STATE="$(get_state)"
  POSITION="$(tmux display-message -p '#{@sidebar-position}' 2>/dev/null || true)"

  # Pane dimensions.
  PANE_WIDTH="$(tmux display-message -p '#{pane_width}' 2>/dev/null || echo 10)"
  PANE_HEIGHT="$(tmux display-message -p '#{pane_height}' 2>/dev/null || echo 1)"

  # Get panes in current window, excluding the sidebar itself.
  PANES_INFO="$(tmux list-panes -F '#{pane_index}|#{pane_title}|#{pane_current_command}|#{pane_active}|#{@sidebar-pane}' 2>/dev/null || true)"

  # Read native status colours.
  BG="$(get_status_bg)"
  FG="$(get_status_fg)"
  [ -z "$BG" ] && BG="default"
  [ -z "$FG" ] && FG="default"

  # Build output.
  OUTPUT=""

  if [ "$POSITION" = "left" ] || [ "$POSITION" = "right" ]; then
    # ── Vertical sidebar ──────────────────────────────────────────
    while IFS='|' read -r idx title cmd active is_sidebar; do
      [ "$is_sidebar" = "1" ] && continue
      [ -z "$idx" ] && continue

      if [ "$STATE" = "collapsed" ]; then
        if [ "$active" = "1" ]; then
          line="▸${idx}"
        else
          line=" ${idx}"
        fi
      else
        # Expanded: show index + command (or title if different from shell).
        display_text=""
        if [ -n "$title" ] && [ "$title" != "$cmd" ]; then
          display_text="${idx}:${title}"
        else
          display_text="${idx}:${cmd}"
        fi
        if [ "$active" = "1" ]; then
          line="▸ ${display_text}"
        else
          line="  ${display_text}"
        fi
      fi

      line="$(fit_width "$line" "$PANE_WIDTH")"

      if [ "$active" = "1" ]; then
        # Reverse video for active pane.
        OUTPUT="${OUTPUT}\033[7m${line}\033[0m\n"
      else
        OUTPUT="${OUTPUT}${line}\n"
      fi
    done <<< "$PANES_INFO"

    # Clear screen and draw.
    printf '\033[2J\033[H'
    printf '%b' "$OUTPUT"

  else
    # ── Horizontal sidebar (top / bottom) ─────────────────────────
    line=""
    while IFS='|' read -r idx title cmd active is_sidebar; do
      [ "$is_sidebar" = "1" ] && continue
      [ -z "$idx" ] && continue

      display_text="${idx}:${cmd}"
      if [ "$active" = "1" ]; then
        line="${line}[${display_text}] "
      else
        line="${line}${display_text} "
      fi
    done <<< "$PANES_INFO"

    printf '\033[2J\033[H'
    echo "$line"

    # If expanded and we have extra rows, print pane titles on subsequent lines.
    if [ "$STATE" = "expanded" ] && [ "$PANE_HEIGHT" -gt 1 ]; then
      extra_line=""
      while IFS='|' read -r idx title cmd active is_sidebar; do
        [ "$is_sidebar" = "1" ] && continue
        [ -z "$idx" ] && continue
        if [ -n "$title" ] && [ "$title" != "$cmd" ]; then
          extra_line="${extra_line}${idx}=${title} "
        fi
      done <<< "$PANES_INFO"

      row=1
      while [ "$row" -lt "$PANE_HEIGHT" ]; do
        if [ "$row" = "1" ] && [ -n "$extra_line" ]; then
          echo "$extra_line"
        else
          echo ""
        fi
        ((row++)) || true
      done
    fi
  fi

  sleep "$REFRESH_INTERVAL"
done
