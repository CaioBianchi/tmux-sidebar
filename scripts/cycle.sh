#!/usr/bin/env bash
#
# Cycle sidebar position: left → right → top → bottom → left
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

CURRENT_POSITION="$(get_position)"
CURRENT_STATE="$(get_state)"

case "$CURRENT_POSITION" in
  left)   NEW_POSITION="right"  ;;
  right)  NEW_POSITION="top"    ;;
  top)    NEW_POSITION="bottom" ;;
  bottom) NEW_POSITION="left"   ;;
  *)      NEW_POSITION="right" ;;
esac

set_position "$NEW_POSITION"
"$CURRENT_DIR/sidebar.sh" create "$NEW_POSITION" "$CURRENT_STATE"
