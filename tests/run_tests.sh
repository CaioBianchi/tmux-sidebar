#!/usr/bin/env bash
#
# Run all tmux-sidebar tests.
#

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

TOTAL_RUN=0
TOTAL_PASSED=0
TOTAL_FAILED=0

echo "=================================="
echo "  tmux-sidebar test suite"
echo "=================================="
echo ""

for test_file in "$SCRIPT_DIR"/test_*.sh; do
  [ -e "$test_file" ] || continue

  name="$(basename "$test_file")"
  echo "Running $name ..."

  # Run the test file in a subshell and capture its summary line.
  output="$($test_file 2>&1)"
  exit_code=$?

  echo "$output"

  # Parse summary.
  run_line="$(echo "$output" | grep 'Tests run:')"
  passed_line="$(echo "$output" | grep 'Tests passed:')"
  failed_line="$(echo "$output" | grep 'Tests failed:')"

  run_count="$(echo "$run_line" | awk '{print $3}')"
  passed_count="$(echo "$passed_line" | awk '{print $3}')"
  failed_count="$(echo "$failed_line" | awk '{print $3}')"

  TOTAL_RUN=$((TOTAL_RUN + run_count))
  TOTAL_PASSED=$((TOTAL_PASSED + passed_count))
  TOTAL_FAILED=$((TOTAL_FAILED + failed_count))

echo ""
done

echo "=================================="
echo "  Grand total"
echo "  Tests run:    $TOTAL_RUN"
echo "  Tests passed: $TOTAL_PASSED"
echo "  Tests failed: $TOTAL_FAILED"
echo "=================================="

if [ "$TOTAL_FAILED" -gt 0 ]; then
  exit 1
fi
exit 0
