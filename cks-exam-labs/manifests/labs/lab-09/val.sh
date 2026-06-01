#!/bin/sh
set -u

CONTAINER_ANSWER=/home/student/bugged-container.txt
SBOM_ANSWER=/home/student/bugged-fruit.spdx

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

if [ -f "$CONTAINER_ANSWER" ]; then
  pass "Is ~/bugged-container.txt present?"
else
  fail "Is ~/bugged-container.txt present?"
fi

if [ -f "$SBOM_ANSWER" ]; then
  pass "Is ~/bugged-fruit.spdx present?"
else
  fail "Is ~/bugged-fruit.spdx present?"
fi

container="$(tr -d '[:space:]' < "$CONTAINER_ANSWER" 2>/dev/null || true)"

if [ "$container" = "banana" ]; then
  pass "Is the container with curl identified?"
else
  fail "Is the container with curl identified?"
fi

if grep -q '"spdxVersion"[[:space:]]*:[[:space:]]*"SPDX-2.3"' "$SBOM_ANSWER" 2>/dev/null; then
  pass "Is the SBOM SPDX JSON?"
else
  fail "Is the SBOM SPDX JSON?"
fi

if grep -q '"name"[[:space:]]*:[[:space:]]*"curlimages/curl:8.10.1"' "$SBOM_ANSWER" 2>/dev/null \
  && grep -q '"name"[[:space:]]*:[[:space:]]*"curl"' "$SBOM_ANSWER" 2>/dev/null; then
  pass "Is the SBOM for the curl container image?"
else
  fail "Is the SBOM for the curl container image?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
