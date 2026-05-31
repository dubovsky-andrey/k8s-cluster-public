#!/bin/sh
set -u

NS=orion
POD=app-xyz
SECRET=a-safe-secret
PASSWORD_FILE=/root/CKS/secrets/CONNECTOR_PASSWORD

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

get_pod_jsonpath() {
  kubectl -n "$NS" get pod "$POD" -o "jsonpath=$1" 2>/dev/null
}

expected_password="$(
  kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.CONNECTOR_PASSWORD}' 2>/dev/null |
    base64 -d 2>/dev/null
)"

if [ -n "$expected_password" ]; then
  pass "Is the connector secret present?"
else
  fail "Is the connector secret present?"
fi

if [ -n "$expected_password" ] && [ -f "$PASSWORD_FILE" ] && [ "$(cat "$PASSWORD_FILE")" = "$expected_password" ]; then
  pass "Is the decoded CONNECTOR_PASSWORD extracted to /root/CKS/secrets?"
else
  fail "Is the decoded CONNECTOR_PASSWORD extracted to /root/CKS/secrets?"
fi

phase="$(get_pod_jsonpath '{.status.phase}')"
if [ "$phase" = "Running" ]; then
  pass "Is the app pod running?"
else
  fail "Is the app pod running?"
fi

env_count="$(
  get_pod_jsonpath '{range .spec.containers[*].env[*]}{.name}{"\n"}{end}' |
    awk '$1 == "CONNECTOR_PASSWORD" { count++ } END { print count + 0 }'
)"
if [ "$env_count" -eq 0 ]; then
  pass "Is CONNECTOR_PASSWORD removed from environment variables?"
else
  fail "Is CONNECTOR_PASSWORD removed from environment variables?"
fi

mount_count="$(
  get_pod_jsonpath '{range .spec.containers[*].volumeMounts[*]}{.name}{"|"}{.mountPath}{"|"}{.readOnly}{"\n"}{end}' |
    awk -F'|' '$2 == "/mnt/connector/password" && $3 == "true" { count++ } END { print count + 0 }'
)"
volume_count="$(
  get_pod_jsonpath '{range .spec.volumes[*]}{.name}{"|"}{.secret.secretName}{"\n"}{end}' |
    awk -F'|' -v secret="$SECRET" '$2 == secret { count++ } END { print count + 0 }'
)"
if [ "$mount_count" -gt 0 ] && [ "$volume_count" -gt 0 ]; then
  pass "Is the secret mounted as a read-only volume at /mnt/connector/password?"
else
  fail "Is the secret mounted as a read-only volume at /mnt/connector/password?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
