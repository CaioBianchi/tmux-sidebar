#!/usr/bin/env bash
#
# Lightweight test framework for tmux-sidebar tests.
# Each test file runs against an isolated tmux server.
#

set -uo pipefail

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0
TMUX_TEST_SOCKET=""

# ── Server lifecycle ────────────────────────────────────────────────

init_test_server() {
  TMUX_TEST_SOCKET="/tmp/tmux-sidebar-test-$$-${RANDOM}.sock"
  rm -f "$TMUX_TEST_SOCKET"
  export TMUX="$TMUX_TEST_SOCKET"
}

cleanup_test_server() {
  if [ -n "$TMUX_TEST_SOCKET" ]; then
    tmux -S "$TMUX_TEST_SOCKET" kill-server 2>/dev/null || true
    rm -f "$TMUX_TEST_SOCKET"
  fi
}

setup_tmux_session() {
  local session="${1:-__tmux_sidebar_test}"
  tmux new-session -d -s "$session" -n test_window 2>/dev/null || true
  sleep 0.3
}

teardown_tmux_session() {
  local session="${1:-__tmux_sidebar_test}"
  tmux kill-session -t "$session" 2>/dev/null || true
}

# ── Assertions ────────────────────────────────────────────────────

assert_equals() {
  local expected="$1"
  local actual="$2"
  local msg="${3:-}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [ "$expected" = "$actual" ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "    ✓ ${msg:-assert_equals}"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "    ✗ ${msg:-assert_equals}"
    echo "      expected: '$expected'"
    echo "      actual:   '$actual'"
  fi
}

assert_true() {
  local cmd="$1"
  local msg="${2:-}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if eval "$cmd" >/dev/null 2>&1; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "    ✓ ${msg:-assert_true}"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "    ✗ ${msg:-assert_true}"
    echo "      command: $cmd"
  fi
}

assert_false() {
  local cmd="$1"
  local msg="${2:-}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if eval "$cmd" >/dev/null 2>&1; then
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "    ✗ ${msg:-assert_false}"
    echo "      command: $cmd"
  else
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "    ✓ ${msg:-assert_false}"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local msg="${3:-}"
  TESTS_RUN=$((TESTS_RUN + 1))
  if [[ "$haystack" == *"$needle"* ]]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
    echo "    ✓ ${msg:-assert_contains}"
  else
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo "    ✗ ${msg:-assert_contains}"
    echo "      expected to contain: '$needle'"
    echo "      actual:              '$haystack'"
  fi
}

summary() {
  echo ""
  echo "========================================"
  echo "  Tests run:    $TESTS_RUN"
  echo "  Tests passed: $TESTS_PASSED"
  echo "  Tests failed: $TESTS_FAILED"
  echo "========================================"
  if [ "$TESTS_FAILED" -gt 0 ]; then
    return 1
  fi
  return 0
}
