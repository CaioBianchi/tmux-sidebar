#!/usr/bin/env bash
#
# Render loop that runs inside the sidebar pane.
# Re-draws content every REFRESH_INTERVAL seconds.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

REFRESH_INTERVAL="$(get_option "@sidebar-refresh-interval" "5")"

# ─── Helpers ───────────────────────────────────────────────────────

# ANSI helpers.
ansi_fg()    { printf '\033[38;5;%sm' "$1"; }
ansi_bg()    { printf '\033[48;5;%sm' "$1"; }
ansi_bold()  { printf '\033[1m'; }
ansi_reset() { printf '\033[0m'; }

# Try to translate a tmux colour name to an ANSI 256 index.
#   "colour46" → 46
#   "red"      → 1
#   "default"  → ""
#   "#ffffff"  → "" (hex not supported here, fall back to ANSI)
colour_to_ansi() {
  local raw="$1"
  if [[ "$raw" =~ ^colour([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [ "$raw" = "default" ] || [ -z "$raw" ]; then
    echo ""
  else
    # Keep a tiny map of common named colours; everything else falls back.
    case "$raw" in
      black)   echo "0"  ;;
      red)     echo "1"  ;;
      green)   echo "2"  ;;
      yellow)  echo "3"  ;;
      blue)    echo "4"  ;;
      magenta) echo "5"  ;;
      cyan)    echo "6"  ;;
      white)   echo "7"  ;;
      *)       echo ""  ;;
    esac
  fi
}

# Resolve accent color to an ANSI fg index.
# Priority:
# 1. @sidebar-accent-color global option
# 2. @sidebar-accent pane-local option (set by sidebar.sh)
# 3. window-status-current-style fg
# 4. Default to tmux "colour4" (blue)
resolve_accent() {
  # 1. global override
  local accent="$(get_option "@sidebar-accent-color" "")"
  if [ -z "$accent" ]; then
    # 2. pane-local override
    accent="$(tmux show-option -pqv '@sidebar-accent' 2>/dev/null || true)"
  fi
  if [ -z "$accent" ]; then
    # 3. tmux active-window fg
    accent="$(get_window_status_current_fg)"
  fi
  if [ -z "$accent" ]; then
    accent="colour4"
  fi
  colour_to_ansi "$accent"
}

# Print text, truncating or padding to exactly $width characters.
fit_width() {
  local text="$1"
  local width="$2"
  local len="${#text}"
  if [ "$len" -gt "$width" ]; then
    printf '%s' "${text:0:$width}"
  else
    printf "%-${width}s" "$text"
  fi
}

# ─── Main loop ─────────────────────────────────────────────────────

while true; do
  STATE="$(get_state)"
  POSITION="$(tmux display-message -p '#{@sidebar-position}' 2>/dev/null || true)"

  PANE_WIDTH="$(tmux display-message -p '#{pane_width}' 2>/dev/null || echo 10)"
  PANE_HEIGHT="$(tmux display-message -p '#{pane_height}' 2>/dev/null || echo 1)"

  PANES_INFO="$(tmux list-panes -F '#{pane_index}|#{pane_title}|#{pane_current_command}|#{pane_active}|#{@sidebar-pane}' 2>/dev/null || true)"

  # Resolve theming.
  ACCENT_NUM="$(resolve_accent)"
  DIM_FG="$(colour_to_ansi "colour8")"   # grey for inactive text

  # Build output.
  OUTPUT=""

  if [ "$POSITION" = "left" ] || [ "$POSITION" = "right" ]; then
    # ── Vertical sidebar ──────────────────────────────────────────
    while IFS='|' read -r idx title cmd active is_sidebar; do
      [ "$is_sidebar" = "1" ] && continue
      [ -z "$idx" ] && continue

      if [ "$STATE" = "collapsed" ]; then
        if [ "$active" = "1" ]; then
          line="${idx}"
        else
          line="${idx}"
        fi
      else
        # Expanded: show index + command (or title if different from shell).
        display_text=""
        if [ -n "$title" ] && [ "$title" != "$cmd" ] && [ "$title" != "$(hostname -s 2>/dev/null)" ]; then
          display_text="${idx}:${title}"
        else
          display_text="${idx}:${cmd}"
        fi
        if [ "$active" = "1" ]; then
          line="${display_text}"
        else
          line="${display_text}"
        fi
      fi

      line="$(fit_width "$line" "$PANE_WIDTH")"

      if [ "$active" = "1" ]; then
        # Compact highlight: only the text itself, not a full-line block.
        if [ -n "$ACCENT_NUM" ]; then
          OUTPUT="${OUTPUT}$(ansi_bold)$(ansi_fg "$ACCENT_NUM")${line}$(ansi_reset)\n"
        else
          OUTPUT="${OUTPUT}$(ansi_bold)${line}$(ansi_reset)\n"
        fi
      else
        # Dimmed inactive item.
        if [ -n "$DIM_FG" ]; then
          OUTPUT="${OUTPUT}$(ansi_fg "$DIM_FG")${line}$(ansi_reset)\n"
        else
          OUTPUT="${OUTPUT}${line}\n"
        fi
      fi
    done <<< "$PANES_INFO"

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
        if [ -n "$ACCENT_NUM" ]; then
          line="${line}$(ansi_bold)$(ansi_fg "$ACCENT_NUM")[${display_text}]$(ansi_reset) "
        else
          line="${line}$(ansi_bold)[${display_text}]$(ansi_reset) "
        fi
      else
        line="${line}${display_text} "
      fi
    done <<< "$PANES_INFO"

    printf '\033[2J\033[H'
    printf '%s\n' "$line"

    # If expanded and we have extra rows, print pane titles on subsequent lines.
    if [ "$STATE" = "expanded" ] && [ "$PANE_HEIGHT" -gt 1 ]; then
      extra_line=""
      while IFS='|' read -r idx title cmd active is_sidebar; do
        [ "$is_sidebar" = "1" ] && continue
        [ -z "$idx" ] && continue
        if [ -n "$title" ] && [ "$title" != "$cmd" ] && [ "$title" != "$(hostname -s 2>/dev/null)" ]; then
          extra_line="${extra_line}${idx}=${title} "
        fi
      done <<< "$PANES_INFO"

      row=1
      while [ "$row" -lt "$PANE_HEIGHT" ]; do
        if [ "$row" = "1" ] && [ -n "$extra_line" ]; then
          printf '%s\n' "$extra_line"
        else
          printf '\n'
        fi
        ((row++)) || true
      done
    fi
  fi

  sleep "$REFRESH_INTERVAL"
done
