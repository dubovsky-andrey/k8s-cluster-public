#!/bin/sh
set -u

DOCKERFILE=/cks/docker/Dockerfile

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

trim_comments() {
  sed 's/[[:space:]]*#.*$//' "$1"
}

if [ -f "$DOCKERFILE" ]; then
  pass "Is the Dockerfile present?"
else
  fail "Is the Dockerfile present?"
  exit 1
fi

docker_clean="$(mktemp)"
trap 'rm -f "$docker_clean"' EXIT
trim_comments "$DOCKERFILE" > "$docker_clean"
docker_joined="$(tr '\n' ' ' < "$docker_clean")"

if grep -Eq '^[[:space:]]*FROM[[:space:]]+ubuntu:24\.04([[:space:]]*)?$' "$docker_clean" \
  && ! grep -Eq '^[[:space:]]*FROM[[:space:]]+[^[:space:]]+:latest([[:space:]]*)?$' "$docker_clean"; then
  pass "Is the base image pinned to a supported non-latest tag?"
else
  fail "Is the base image pinned to a supported non-latest tag?"
fi

if printf '%s\n' "$docker_joined" | grep -Eq 'apt-get update[[:space:]]*&&.*apt-get install[[:space:]]+-y[[:space:]]+--no-install-recommends' \
  && grep -Eq 'rm -rf /var/lib/apt/lists/\*' "$docker_clean" \
  && ! grep -Eq 'apt-get install[[:space:]]+-y[[:space:]]*(\\|$)' "$docker_clean"; then
  pass "Is apt usage cache-safe and minimal?"
else
  fail "Is apt usage cache-safe and minimal?"
fi

if grep -Eq '^[[:space:]]*ARG[[:space:]]+APP_VERSION=1\.0\.0([[:space:]]*)?$' "$docker_clean" \
  && ! grep -Eq '^[[:space:]]*ARG[[:space:]]+APP_VERSION=latest([[:space:]]*)?$' "$docker_clean"; then
  pass "Is the application build version pinned?"
else
  fail "Is the application build version pinned?"
fi

if ! grep -Eiq '(^|[[:space:]])(telnet|netcat-traditional|gcc|make|sudo)([[:space:]]|\\|$)' "$docker_clean"; then
  pass "Are unnecessary risky packages removed?"
else
  fail "Are unnecessary risky packages removed?"
fi

if grep -Eq '^[[:space:]]*COPY[[:space:]]+app\.tar\.gz[[:space:]]+/opt/app/?([[:space:]]*)?$' "$docker_clean" \
  && ! grep -Eq '^[[:space:]]*ADD[[:space:]]+' "$docker_clean"; then
  pass "Is COPY used instead of ADD for the local application archive?"
else
  fail "Is COPY used instead of ADD for the local application archive?"
fi

if ! grep -Eq 'chmod[[:space:]]+(777|4777|u\+s|g\+s)' "$docker_clean"; then
  pass "Are unsafe file permissions removed?"
else
  fail "Are unsafe file permissions removed?"
fi

if grep -Eq '^[[:space:]]*WORKDIR[[:space:]]+/opt/app([[:space:]]*)?$' "$docker_clean"; then
  pass "Is the working directory explicit and application-scoped?"
else
  fail "Is the working directory explicit and application-scoped?"
fi

if grep -Eq '^[[:space:]]*ENV[[:space:]]+NGINX_PORT=8080([[:space:]]*)?$' "$docker_clean" \
  && grep -Eq '^[[:space:]]*EXPOSE[[:space:]]+8080([[:space:]]*)?$' "$docker_clean"; then
  pass "Is the container configured for an unprivileged port?"
else
  fail "Is the container configured for an unprivileged port?"
fi

user_count="$(
  grep -E '^[[:space:]]*USER[[:space:]]+' "$docker_clean" |
  wc -l |
  tr -d ' '
)"
docker_user="$(
  awk 'toupper($1) == "USER" { print $2 }' "$docker_clean" |
  tail -n 1
)"
if [ "$user_count" -eq 1 ] && [ "$docker_user" = "65535" ]; then
  pass "Is the Dockerfile configured to run as UID 65535?"
else
  fail "Is the Dockerfile configured to run as UID 65535?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
