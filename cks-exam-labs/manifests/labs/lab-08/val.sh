#!/bin/sh
set -u

ANSWER=/opt/course/security-issues.txt

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

if [ -f "$ANSWER" ]; then
  pass "Is /opt/course/security-issues.txt present?"
else
  fail "Is /opt/course/security-issues.txt present?"
  exit 1
fi

normalized="$(
  sed 's/[[:space:]]*$//' "$ANSWER" |
    sed '/^[[:space:]]*$/d' |
    sort -u
)"

expected="$(printf '%s\n' /opt/course/q3_file1.Dockerfile /opt/course/q3_file2.yaml | sort)"

if [ "$normalized" = "$expected" ]; then
  pass "Are exactly the files with credential exposure listed?"
else
  fail "Are exactly the files with credential exposure listed?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
