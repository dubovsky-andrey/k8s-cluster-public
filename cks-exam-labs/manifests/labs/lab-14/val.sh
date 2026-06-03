#!/bin/sh
set -u

NS=galaxy
DEPLOYMENT=gamma

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

deployment_json="$(kubectl -n "$NS" get deployment "$DEPLOYMENT" -o json 2>/dev/null || true)"
if [ -n "$deployment_json" ]; then
  pass "Does deployment $DEPLOYMENT exist in namespace $NS?"
else
  fail "Does deployment $DEPLOYMENT exist in namespace $NS?"
  exit 1
fi

if printf '%s\n' "$deployment_json" | jq -e '
  .spec.replicas == 1
  and (.spec.selector.matchLabels.app == "gamma")
  and (.spec.template.metadata.labels.app == "gamma")
  and (.spec.template.spec.containers | length == 2)
  and ([.spec.template.spec.containers[].name] | sort == ["api", "sidecar"])
  and ([.spec.template.spec.containers[].image] | unique == ["busybox:1.36"])
  and ([.spec.template.spec.containers[].command] | all(. == ["sleep", "3600"]))
' >/dev/null 2>&1; then
  pass "Were the original deployment fields preserved?"
else
  fail "Were the original deployment fields preserved?"
fi

container_count="$(printf '%s\n' "$deployment_json" | jq '.spec.template.spec.containers | length' 2>/dev/null || printf '0')"
secure_count="$(
  printf '%s\n' "$deployment_json" |
  jq '
    [
      .spec.template.spec.containers[]
      | select(
          .securityContext.runAsUser == 1001
          and .securityContext.allowPrivilegeEscalation == false
          and .securityContext.readOnlyRootFilesystem == true
        )
    ] | length
  ' 2>/dev/null || printf '0'
)"

if [ "$container_count" -gt 0 ] && [ "$secure_count" -eq "$container_count" ]; then
  pass "Do all containers have the required securityContext?"
else
  fail "Do all containers have the required securityContext?"
fi

ready="$(kubectl -n "$NS" get deployment "$DEPLOYMENT" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
if [ "${ready:-0}" -gt 0 ]; then
  pass "Is the gamma deployment ready?"
else
  fail "Is the gamma deployment ready?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
