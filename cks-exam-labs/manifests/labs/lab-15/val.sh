#!/bin/sh
set -u

API=/etc/kubernetes/manifests/kube-apiserver.yaml
POLICY=/etc/kubernetes/cluster-policy.yaml
LOG=/var/log/cluster-audit.log

failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
has() { grep -q -- "$1" "$2" 2>/dev/null; }

for flag in \
  '--audit-policy-file=/etc/kubernetes/cluster-policy.yaml' \
  '--audit-log-path=/var/log/cluster-audit.log' \
  '--audit-log-maxage=10' \
  '--audit-log-maxbackup=3' \
  '--audit-log-maxsize=10'; do
  has "$flag" "$API" || fail "Is kube-apiserver configured with $flag?"
done

if [ "$failures" -eq 0 ]; then
  pass "Are all required audit flags configured?"
fi

if has 'mountPath: /etc/kubernetes/cluster-policy.yaml' "$API" \
  && has 'mountPath: /var/log' "$API" \
  && has 'name: audit-policy' "$API" \
  && has 'name: varlog' "$API" \
  && has 'path: /etc/kubernetes/cluster-policy.yaml' "$API" \
  && has 'path: /var/log' "$API" \
  && has 'type: File' "$API" \
  && has 'type: Directory' "$API"; then
  pass "Are the audit policy and log directories mounted into kube-apiserver?"
else
  fail "Are the audit policy and log directories mounted into kube-apiserver?"
fi

if has 'apiVersion: audit.k8s.io/v1' "$POLICY" && has 'kind: Policy' "$POLICY" && has 'RequestReceived' "$POLICY"; then
  pass "Is the audit policy file valid and omitting RequestReceived?"
else
  fail "Is the audit policy file valid and omitting RequestReceived?"
fi

if has 'level: Metadata' "$POLICY" \
  && has 'delete' "$POLICY" \
  && has 'secrets' "$POLICY" \
  && has 'kube-system' "$POLICY"; then
  pass "Does the policy track kube-system secret deletes at Metadata level?"
else
  fail "Does the policy track kube-system secret deletes at Metadata level?"
fi

if has 'level: Request' "$POLICY" \
  && has 'create' "$POLICY" \
  && has 'update' "$POLICY" \
  && has 'patch' "$POLICY" \
  && has 'delete' "$POLICY" \
  && has 'apps' "$POLICY" \
  && has 'deployments' "$POLICY" \
  && has 'default' "$POLICY"; then
  pass "Does the policy track default deployment changes at Request level?"
else
  fail "Does the policy track default deployment changes at Request level?"
fi

if [ "$(grep -c 'level: Metadata' "$POLICY" 2>/dev/null || printf 0)" -ge 2 ]; then
  pass "Does the policy include a Metadata catch-all rule?"
else
  fail "Does the policy include a Metadata catch-all rule?"
fi

kubectl get pods -n kube-system >/tmp/cks-kube-system-pods 2>/dev/null || true
if grep -q 'kube-apiserver-controlplane.*Running' /tmp/cks-kube-system-pods 2>/dev/null; then
  pass "Is kube-apiserver running?"
else
  fail "Is kube-apiserver running?"
fi

if [ -f "$LOG" ]; then
  pass "Was the audit log file created at $LOG?"
else
  fail "Was the audit log file created at $LOG?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
