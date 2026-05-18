#!/usr/bin/env bash
#
# Cycle sidebar position: left → right → left
#

set -euo pipefail

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$CURRENT_DIR/helpers.sh"

CURRENT_POSITION="$(get_position)"

case "$CURRENT_POSITION" in
  left)   NEW_POSITION="right" ;;
  right)  NEW_POSITION="left"  ;;
  *)      NEW_POSITION="left" ;;
esac

set_position "$NEW_POSITION"
"$CURRENT_DIR/sidebar.sh" create "$NEW_POSITION"
