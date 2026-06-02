#!/bin/sh
set -u

NS=restricted
DEPLOYMENT=web-server
IMAGE=nginxinc/nginx-unprivileged:1.27-alpine

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
else
  pass "Does namespace $NS exist?"
fi

if [ "$(kubectl get namespace "$NS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)" = "restricted" ]; then
  pass "Is Pod Security restricted enforcement still enabled?"
else
  fail "Is Pod Security restricted enforcement still enabled?"
fi

if ! kubectl -n "$NS" get deployment "$DEPLOYMENT" >/dev/null 2>&1; then
  fail "Does deployment $DEPLOYMENT exist?"
  exit 1
else
  pass "Does deployment $DEPLOYMENT exist?"
fi

if [ "$(get_jsonpath '{.spec.template.spec.containers[0].image}')" = "$IMAGE" ]; then
  pass "Is the container image unchanged?"
else
  fail "Is the container image unchanged?"
fi

desired="$(get_jsonpath '{.spec.replicas}')"
ready="$(get_jsonpath '{.status.readyReplicas}')"
if [ "${ready:-0}" = "${desired:-1}" ] && [ "${ready:-0}" -gt 0 ]; then
  pass "Is the deployment ready?"
else
  fail "Is the deployment ready?"
fi

container_count="$(get_jsonpath '{.spec.template.spec.containers[*].name}' | wc -w | tr -d ' ')"
safe_context_count="$(
  kubectl -n "$NS" get deployment "$DEPLOYMENT" -o json 2>/dev/null |
  jq '
    [
      .spec.template.spec.containers[]
      | select(
          (.securityContext.allowPrivilegeEscalation == false)
          and ((.securityContext.capabilities.drop // []) | index("ALL"))
          and (
            (.securityContext.runAsNonRoot == true)
            or (.securityContext.runAsUser != null and .securityContext.runAsUser != 0)
            or (.securityContext.runAsUser == null and .securityContext.runAsNonRoot == null and .securityContext.allowPrivilegeEscalation == false)
          )
          and (
            (.securityContext.seccompProfile.type == "RuntimeDefault")
            or (.securityContext.seccompProfile.type == "Localhost")
            or (.securityContext.seccompProfile == null)
          )
          and (.securityContext.runAsUser != 0)
        )
    ] | length
  ' 2>/dev/null || printf '0'
)"

if [ "$container_count" -gt 0 ] && [ "$safe_context_count" -eq "$container_count" ]; then
  pass "Does the container securityContext satisfy the restricted policy?"
else
  fail "Does the container securityContext satisfy the restricted policy?"
fi

pod_count="$(
  kubectl -n "$NS" get pods -l app=web-server -o jsonpath='{.items[*].metadata.name}' 2>/dev/null |
  wc -w |
  tr -d ' '
)"
if [ "$pod_count" -gt 0 ]; then
  pass "Did the ReplicaSet create a pod?"
else
  fail "Did the ReplicaSet create a pod?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
