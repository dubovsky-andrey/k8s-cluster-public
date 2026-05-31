#!/bin/sh
set -u

DOCKERFILE=/cks/docker/Dockerfile
MANIFEST=/cks/docker/deployment.yaml

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

if [ -f "$DOCKERFILE" ] && [ -f "$MANIFEST" ]; then
  pass "Are the review files present?"
else
  fail "Are the review files present?"
  exit 1
fi

user_count="$(
  grep -E '^[[:space:]]*USER[[:space:]]+' "$DOCKERFILE" |
  wc -l |
  tr -d ' '
)"
docker_user="$(
  awk 'toupper($1) == "USER" { print $2 }' "$DOCKERFILE" |
  tail -n 1
)"

if [ "$user_count" -eq 1 ] && [ "$docker_user" = "65535" ]; then
  pass "Is the Dockerfile configured to run as UID 65535?"
else
  fail "Is the Dockerfile configured to run as UID 65535?"
fi

if grep -Eiq '^[[:space:]]*USER[[:space:]]+root([[:space:]]|$)' "$DOCKERFILE"; then
  fail "Is root removed from the Dockerfile runtime user?"
else
  pass "Is root removed from the Dockerfile runtime user?"
fi

if grep -Eq '^[[:space:]]*kind:[[:space:]]*Deployment([[:space:]]*)?$' "$MANIFEST" \
  && grep -Eq '^[[:space:]]*name:[[:space:]]*docker-review([[:space:]]*)?$' "$MANIFEST"; then
  pass "Is the Deployment manifest still present?"
else
  fail "Is the Deployment manifest still present?"
fi

privileged_count="$(
  grep -E '^[[:space:]]*privileged:' "$MANIFEST" |
  wc -l |
  tr -d ' '
)"
if [ "$privileged_count" -eq 1 ] \
  && grep -Eq '^[[:space:]]*privileged:[[:space:]]*false([[:space:]]*#.*)?$' "$MANIFEST"; then
  pass "Is privileged mode disabled in the Deployment?"
else
  fail "Is privileged mode disabled in the Deployment?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
