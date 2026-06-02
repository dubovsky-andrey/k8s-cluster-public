#!/bin/sh
set -u

NS=products
POLICY=allow-traffic-to-products

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

if ! kubectl get namespace products >/dev/null 2>&1 \
  || ! kubectl get namespace database >/dev/null 2>&1 \
  || ! kubectl get namespace payments >/dev/null 2>&1; then
  fail "Do the products, database, and payments namespaces exist?"
  exit 1
else
  pass "Do the products, database, and payments namespaces exist?"
fi

if ! kubectl -n products get deployment web-app >/dev/null 2>&1 \
  || ! kubectl -n database get deployment product-db >/dev/null 2>&1; then
  fail "Do the required workloads exist?"
  exit 1
else
  pass "Do the required workloads exist?"
fi

policy_json="$(kubectl -n "$NS" get networkpolicy "$POLICY" -o json 2>/dev/null || true)"
if [ -z "$policy_json" ]; then
  fail "Does NetworkPolicy $POLICY exist in namespace $NS?"
  exit 1
else
  pass "Does NetworkPolicy $POLICY exist in namespace $NS?"
fi

if printf '%s\n' "$policy_json" | jq -e '
  (.spec.policyTypes // []) | index("Ingress")
' >/dev/null 2>&1; then
  pass "Does the policy apply to ingress traffic?"
else
  fail "Does the policy apply to ingress traffic?"
fi

if printf '%s\n' "$policy_json" | jq -e '
  (.spec.podSelector.matchLabels.app == "web-app")
' >/dev/null 2>&1; then
  pass "Does the policy select the web-app workload?"
else
  fail "Does the policy select the web-app workload?"
fi

if printf '%s\n' "$policy_json" | jq -e '
  [
    (.spec.ingress // [])[]?.from[]?
    | select(
        (.namespaceSelector.matchLabels["kubernetes.io/metadata.name"] == "database")
        and (.podSelector.matchLabels.app == "database")
      )
  ] | length > 0
' >/dev/null 2>&1; then
  pass "Does the policy allow product-db traffic from the database namespace?"
else
  fail "Does the policy allow product-db traffic from the database namespace?"
fi

if printf '%s\n' "$policy_json" | jq -e '
  [
    (.spec.ingress // [])[]?.from[]?
    | select(
        (.namespaceSelector.matchLabels["kubernetes.io/metadata.name"] == "payments")
        and (
          (.podSelector | not)
          or ((.podSelector.matchLabels // {}) == {} and (.podSelector.matchExpressions // []) == [])
        )
      )
  ] | length > 0
' >/dev/null 2>&1; then
  pass "Does the policy allow all traffic from the payments namespace?"
else
  fail "Does the policy allow all traffic from the payments namespace?"
fi

if printf '%s\n' "$policy_json" | jq -e '
  [
    (.spec.ingress // [])[]?
    | select(. == {} or ((.from // [])[]? | (.namespaceSelector | not) and (.podSelector | not)))
  ] | length == 0
' >/dev/null 2>&1; then
  pass "Does the policy avoid broad ingress allow rules?"
else
  fail "Does the policy avoid broad ingress allow rules?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
