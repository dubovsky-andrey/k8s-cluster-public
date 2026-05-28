#!/bin/sh
set -u

NS=sec-ns
DEPLOYMENT=secdep
EXPECTED_USER=30000

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

get_jsonpath() {
  kubectl -n "$NS" get deployment "$DEPLOYMENT" -o "jsonpath=$1" 2>/dev/null
}

if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  fail "Does namespace $NS exist?"
  exit 1
fi

if ! kubectl -n "$NS" get deployment "$DEPLOYMENT" >/dev/null 2>&1; then
  fail "Does deployment $DEPLOYMENT exist?"
  exit 1
fi

desired="$(get_jsonpath '{.spec.replicas}')"
ready="$(get_jsonpath '{.status.readyReplicas}')"
if [ "${ready:-0}" = "${desired:-1}" ]; then
  pass "Is the deployment ready?"
else
  fail "Is the deployment ready?"
fi

container_count="$(get_jsonpath '{.spec.template.spec.containers[*].name}' | wc -w | tr -d ' ')"
secure_count="$(
  kubectl -n "$NS" get deployment "$DEPLOYMENT" -o jsonpath='{range .spec.template.spec.containers[*]}{.securityContext.runAsUser}{" "}{.securityContext.readOnlyRootFilesystem}{" "}{.securityContext.allowPrivilegeEscalation}{"\n"}{end}' |
  awk -v user="$EXPECTED_USER" '$1 == user && $2 == "true" && $3 == "false" { count++ } END { print count + 0 }'
)"

if [ "$container_count" -gt 0 ] && [ "$secure_count" -eq "$container_count" ]; then
  pass "Do all containers use the required security context?"
else
  fail "Do all containers use the required security context?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
