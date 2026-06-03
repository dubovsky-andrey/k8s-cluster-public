#!/bin/sh
set -u

NS=automated
SA=bot-sa
DEPLOYMENT=sweeper

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

deployment_json="$(kubectl -n "$NS" get deployment "$DEPLOYMENT" -o json 2>/dev/null || true)"
sa_json="$(kubectl -n "$NS" get serviceaccount "$SA" -o json 2>/dev/null || true)"

if [ -n "$sa_json" ]; then
  pass "Does ServiceAccount $SA exist?"
else
  fail "Does ServiceAccount $SA exist?"
fi

if [ -n "$sa_json" ] && printf '%s\n' "$sa_json" | jq -e '.automountServiceAccountToken == false' >/dev/null 2>&1; then
  pass "Does ServiceAccount $SA disable automatic token mounting?"
else
  fail "Does ServiceAccount $SA disable automatic token mounting?"
fi

if [ -n "$deployment_json" ]; then
  pass "Does deployment $DEPLOYMENT exist?"
else
  fail "Does deployment $DEPLOYMENT exist?"
  exit 1
fi

if printf '%s\n' "$deployment_json" | jq -e '
  .spec.replicas == 1
  and (.spec.selector.matchLabels.app == "sweeper")
  and (.spec.template.metadata.labels.app == "sweeper")
  and (.spec.template.spec.containers | length == 1)
  and (.spec.template.spec.containers[0].name == "sweeper")
  and (.spec.template.spec.containers[0].image == "busybox:1.36")
  and (.spec.template.spec.containers[0].command == ["sleep", "3600"])
' >/dev/null 2>&1; then
  pass "Were the original deployment fields preserved?"
else
  fail "Were the original deployment fields preserved?"
fi

if printf '%s\n' "$deployment_json" | jq -e '
  .spec.template.spec.serviceAccountName == "bot-sa"
  and .spec.template.spec.automountServiceAccountToken == false
' >/dev/null 2>&1; then
  pass "Does the deployment use bot-sa without automatic token mounting?"
else
  fail "Does the deployment use bot-sa without automatic token mounting?"
fi

if printf '%s\n' "$deployment_json" | jq -e '
  [
    .spec.template.spec.volumes[]?
    | select(
        .name == "sa-token"
        and (
          [
            .projected.sources[]?.serviceAccountToken
            | select(.path == "bot-token" and .audience == "default" and .expirationSeconds == 3600)
          ] | length > 0
        )
      )
  ] | length > 0
' >/dev/null 2>&1; then
  pass "Is the ServiceAccount token projected with the required path, audience, and expiration?"
else
  fail "Is the ServiceAccount token projected with the required path, audience, and expiration?"
fi

if printf '%s\n' "$deployment_json" | jq -e '
  [
    .spec.template.spec.containers[]?
    | select(
        [
          .volumeMounts[]?
          | select(.name == "sa-token" and .mountPath == "/var/run/secrets/tokens" and .readOnly == true)
        ] | length > 0
      )
  ] | length > 0
' >/dev/null 2>&1; then
  pass "Is the projected token mounted read-only at /var/run/secrets/tokens?"
else
  fail "Is the projected token mounted read-only at /var/run/secrets/tokens?"
fi

ready="$(kubectl -n "$NS" get deployment "$DEPLOYMENT" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
if [ "${ready:-0}" -gt 0 ]; then
  pass "Is the sweeper deployment ready?"
else
  fail "Is the sweeper deployment ready?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
