#!/bin/sh
set -u

NS=omni
POD=frontend-site
EXPECTED_PROFILE=restricted-frontend
EXPECTED_SA=frontend-default

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

get_jsonpath() {
  kubectl -n "$NS" get pod "$POD" -o "jsonpath=$1" 2>/dev/null
}

if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  fail "Is the pod running?"
  exit 1
fi

if ! kubectl -n "$NS" get pod "$POD" >/dev/null 2>&1; then
  fail "Is the pod running?"
  exit 1
fi

phase="$(get_jsonpath '{.status.phase}')"
if [ "$phase" = "Running" ]; then
  pass "Is the pod running?"
else
  fail "Is the pod running?"
fi

sa="$(get_jsonpath '{.spec.serviceAccountName}')"
if [ "$sa" = "$EXPECTED_SA" ]; then
  pass "Is the correct service account used?"
else
  fail "Is the correct service account used?"
fi

profile_type="$(get_jsonpath '{.spec.securityContext.appArmorProfile.type}')"
profile_name="$(get_jsonpath '{.spec.securityContext.appArmorProfile.localhostProfile}')"
obsolete_deleted=true
for unused_sa in frontend fe; do
  if kubectl -n "$NS" get sa "$unused_sa" >/dev/null 2>&1; then
    obsolete_deleted=false
  fi
done
if [ "$obsolete_deleted" = "true" ]; then
  pass "Are obsolete service accounts deleted?"
else
  fail "Are obsolete service accounts deleted?"
fi

internal_status="$(
  kubectl -n "$NS" exec "$POD" -- sh -c \
    'wget -qS -O- http://127.0.0.1/internal/' \
    2>&1 || true
)"

if [ "$profile_type" = "Localhost" ] && [ "$profile_name" = "$EXPECTED_PROFILE" ] \
  && ! printf '%s\n' "$internal_status" | grep -q 'Internal Site' \
  && printf '%s\n' "$internal_status" | grep -Eq '403|Permission denied|Operation not permitted|denied'; then
  pass "Is the internal-site restricted?"
else
  fail "Is the internal-site restricted?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
