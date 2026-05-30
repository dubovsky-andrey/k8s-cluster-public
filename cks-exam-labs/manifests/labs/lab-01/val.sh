#!/bin/sh
set -u

NS=task-01
DEPLOYMENT=insecure-web
SERVICE=insecure-web

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
privileged_count="$(
  get_jsonpath '{range .spec.template.spec.containers[*]}{.securityContext.privileged}{"\n"}{end}' |
  awk '$1 == "true" { count++ } END { print count + 0 }'
)"
escalation_count="$(
  get_jsonpath '{range .spec.template.spec.containers[*]}{.securityContext.allowPrivilegeEscalation}{"\n"}{end}' |
  awk '$1 == "false" { count++ } END { print count + 0 }'
)"

pod_run_as_user="$(get_jsonpath '{.spec.template.spec.securityContext.runAsUser}')"
pod_run_as_non_root="$(get_jsonpath '{.spec.template.spec.securityContext.runAsNonRoot}')"
non_root_count="$(
  get_jsonpath '{range .spec.template.spec.containers[*]}{.securityContext.runAsUser}{"|"}{.securityContext.runAsNonRoot}{"\n"}{end}' |
  awk -F'|' -v pod_user="$pod_run_as_user" -v pod_non_root="$pod_run_as_non_root" '
    {
      user = $1
      non_root = $2
      if (user == "" || user == "<no value>") {
        user = pod_user
      }
      if (non_root == "" || non_root == "<no value>") {
        non_root = pod_non_root
      }
      if ((user != "" && user != "<no value>" && user != "0") || non_root == "true") {
        count++
      }
    }
    END { print count + 0 }
  '
)"

if [ "$container_count" -gt 0 ] \
  && [ "$privileged_count" -eq 0 ] \
  && [ "$escalation_count" -eq "$container_count" ] \
  && [ "$non_root_count" -eq "$container_count" ]; then
  pass "Is the workload security context hardened?"
else
  fail "Is the workload security context hardened?"
fi

workload_sa="$(get_jsonpath '{.spec.template.spec.serviceAccountName}')"
workload_sa="${workload_sa:-default}"
if kubectl auth can-i '*' '*' --as="system:serviceaccount:${NS}:${workload_sa}" -n "$NS" 2>/dev/null | grep -qx 'yes'; then
  fail "Is wildcard RBAC access removed from the workload service account?"
else
  pass "Is wildcard RBAC access removed from the workload service account?"
fi

network_json="$(kubectl -n "$NS" get networkpolicy -o json 2>/dev/null || true)"
network_policy_count="$(printf '%s\n' "$network_json" | jq '.items | length' 2>/dev/null || printf '0')"
open_rule_count="$(
  printf '%s\n' "$network_json" |
  jq '[.items[] | (.spec.ingress // [])[]?, (.spec.egress // [])[]? | select(. == {})] | length' 2>/dev/null ||
  printf '0'
)"
default_deny_count="$(
  printf '%s\n' "$network_json" |
  jq '[.items[] | select(
    ((.spec.podSelector.matchLabels // {}) == {}) and
    ((.spec.podSelector.matchExpressions // []) == []) and
    ((.spec.policyTypes // []) | index("Ingress")) and
    ((.spec.policyTypes // []) | index("Egress")) and
    ((.spec.ingress // []) | length == 0) and
    ((.spec.egress // []) | length == 0)
  )] | length' 2>/dev/null ||
  printf '0'
)"

if [ "$network_policy_count" -gt 0 ] \
  && [ "$open_rule_count" -eq 0 ] \
  && [ "$default_deny_count" -gt 0 ]; then
  pass "Is default network access restricted?"
else
  fail "Is default network access restricted?"
fi

endpoint_count="$(
  kubectl -n "$NS" get endpoints "$SERVICE" -o jsonpath='{.subsets[*].addresses[*].ip}' 2>/dev/null |
  wc -w |
  tr -d ' '
)"
if [ "$endpoint_count" -gt 0 ]; then
  pass "Is the web application still reachable inside the namespace?"
else
  fail "Is the web application still reachable inside the namespace?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
