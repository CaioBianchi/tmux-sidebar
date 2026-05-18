#!/usr/bin/env bash
#
# Interactive render loop that runs inside the sidebar pane.
# Shows pane list; use Up/Down (or k/j) to select, Enter to focus.
# Mouse clicks on rows switch focus.
# Mouse wheel scrolls selection.
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

# Enable mouse tracking on entry, disable on exit.
printf '\e[?1000h\e[?1006h'
trap 'printf "\e[?1000l\e[?1006l"' EXIT

# ANSI helpers
ansi_fg()    { printf '\033[38;5;%sm' "$1"; }
ansi_bg()    { printf '\033[48;5;%sm' "$1"; }
ansi_bold()  { printf '\033[1m'; }
ansi_reset() { printf '\033[0m'; }

colour_to_ansi() {
  local raw="$1"
  if [[ "$raw" =~ ^colour([0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
  elif [ "$raw" = "default" ] || [ -z "$raw" ]; then
    echo ""
  else
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

resolve_accent() {
  local accent="$(get_option "@sidebar-accent-color" "")"
  if [ -z "$accent" ]; then
    accent="$(tmux show-option -pqv '@sidebar-accent' 2>/dev/null || true)"
  fi
  if [ -z "$accent" ]; then
    accent="$(get_window_status_current_fg)"
  fi
  if [ -z "$accent" ]; then
    accent="colour4"
  fi
  colour_to_ansi "$accent"
}

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

# Parse an SGR mouse sequence: ESC [ < Bt ; Cx ; Cy M/m
# Returns "btn cx cy" on stdout.
parse_sgr_mouse() {
  local seq="$1"
  # strip leading ESC[< and trailing M/m
  local inner="${seq#*<}"
  inner="${inner%[Mm]}"
  local IFS=';'
  local -a parts
  read -ra parts <<< "$inner"
  printf '%s %s %s' "${parts[0]}" "${parts[1]}" "${parts[2]}"
}

read_key() {
  local key=""
  if IFS= read -rs -t 2 -n1 key; then
    if [[ "$key" == $'\e' ]]; then
      local rest=""
      IFS= read -rs -t 0.1 -n10 rest || true
      key="$key$rest"
    fi
    printf '%s' "$key"
  else
    # timeout -- use a sentinel so we don't confuse it with Enter
    printf 'TIMEOUT'
  fi
}

selected=0

while true; do
  PANES_INFO="$(tmux list-panes -F '#{pane_index}|#{pane_title}|#{pane_current_command}|#{pane_active}|#{@sidebar-pane}|#{pane_id}' 2>/dev/null || true)"

  # Build arrays
  panes=()
  pane_ids=()
  pane_titles=()
  pane_cmds=()
  pane_actives=()

  while IFS='|' read -r idx title cmd active is_sidebar pane_id; do
    [ "$is_sidebar" = "1" ] && continue
    [ -z "$idx" ] && continue
    panes+=("$idx")
    pane_ids+=("$pane_id")
    pane_titles+=("$title")
    pane_cmds+=("$cmd")
    pane_actives+=("$active")
  done <<< "$PANES_INFO"

  pane_count=${#panes[@]}

  if [ "$pane_count" -eq 0 ]; then
    printf '\033[2J\033[H'
    printf "No panes\n"
    sleep 2
    continue
  fi

  if [ "$selected" -ge "$pane_count" ]; then
    selected=$((pane_count - 1))
  fi
  if [ "$selected" -lt 0 ]; then
    selected=0
  fi

  PANE_WIDTH="$(tmux display-message -p '#{pane_width}' 2>/dev/null || echo 10)"

  ACCENT_NUM="$(resolve_accent)"
  DIM_FG="$(colour_to_ansi "colour8")"

  # Account for the 2-char prefix ("> " or "  ") so lines don't wrap.
  content_width=$((PANE_WIDTH - 2))
  [ "$content_width" -lt 1 ] && content_width=1

  # Draw
  printf '\033[2J\033[H'

  for i in "${!panes[@]}"; do
    idx="${panes[$i]}"
    title="${pane_titles[$i]}"
    cmd="${pane_cmds[$i]}"
    active="${pane_actives[$i]}"

    display_text=""
    if [ -n "$title" ] && [ "$title" != "$cmd" ] && [ "$title" != "$(hostname -s 2>/dev/null)" ]; then
      display_text="${idx}:${title}"
    else
      display_text="${idx}:${cmd}"
    fi

    line="$(fit_width "$display_text" "$content_width")"

    if [ "$i" -eq "$selected" ]; then
      if [ "$active" = "1" ] && [ -n "$ACCENT_NUM" ]; then
        printf "$(ansi_bold)$(ansi_fg "$ACCENT_NUM")> %s$(ansi_reset)\n" "$line"
      elif [ "$active" = "1" ]; then
        printf "$(ansi_bold)> %s$(ansi_reset)\n" "$line"
      elif [ -n "$DIM_FG" ]; then
        printf "$(ansi_fg "$DIM_FG")> %s$(ansi_reset)\n" "$line"
      else
        printf "> %s\n" "$line"
      fi
    elif [ "$active" = "1" ]; then
      if [ -n "$ACCENT_NUM" ]; then
        printf "  $(ansi_bold)$(ansi_fg "$ACCENT_NUM")%s$(ansi_reset)\n" "$line"
      else
        printf "  $(ansi_bold)%s$(ansi_reset)\n" "$line"
      fi
    else
      if [ -n "$DIM_FG" ]; then
        printf "  $(ansi_fg "$DIM_FG")%s$(ansi_reset)\n" "$line"
      else
        printf "  %s\n" "$line"
      fi
    fi
  done

  # Read key
  key="$(read_key)"

  case "$key" in
    TIMEOUT)
      : # just refresh the display
      ;;
    $'\e[A'|'k')
      selected=$((selected - 1))
      [ "$selected" -lt 0 ] && selected=0
      ;;
    $'\e[B'|'j')
      selected=$((selected + 1))
      [ "$selected" -ge "$pane_count" ] && selected=$((pane_count - 1))
      ;;
    $'\n'|$'\r')
      target_id="${pane_ids[$selected]}"
      tmux select-pane -t "$target_id"
      ;;
    # SGR left-click press or release
    $'\e[<0;'*'M'|$'\e[<0;'*'m')
      read -r btn cx cy <<< "$(parse_sgr_mouse "$key")"
      # cy is 1-indexed; our list starts at row 1.
      clicked_idx=$((cy - 1))
      if [ "$clicked_idx" -ge 0 ] && [ "$clicked_idx" -lt "$pane_count" ]; then
        selected="$clicked_idx"
        target_id="${pane_ids[$selected]}"
        tmux select-pane -t "$target_id"
      fi
      ;;
    # SGR wheel up (64) / wheel down (65)
    $'\e[<64;'*'M')
      selected=$((selected - 1))
      [ "$selected" -lt 0 ] && selected=0
      ;;
    $'\e[<65;'*'M')
      selected=$((selected + 1))
      [ "$selected" -ge "$pane_count" ] && selected=$((pane_count - 1))
      ;;
  esac
done
