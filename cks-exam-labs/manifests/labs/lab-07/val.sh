#!/bin/sh
set -u

KUBELET_SERVICE=/usr/lib/systemd/system/kubelet.service
KUBELET_CONFIG=/var/lib/kubelet/config.yaml
ETCD_DIR=/var/lib/etcd
CONTROLLER_MANAGER=/etc/kubernetes/manifests/kube-controller-manager.yaml
SCHEDULER=/etc/kubernetes/manifests/kube-scheduler.yaml

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

file_mode() {
  stat -c '%a' "$1" 2>/dev/null || true
}

owner_group() {
  stat -c '%U:%G' "$1" 2>/dev/null || true
}

require_file() {
  if [ -f "$1" ]; then
    pass "Is $1 present?"
  else
    fail "Is $1 present?"
    return 1
  fi
}

require_file "$KUBELET_SERVICE" || exit 1
require_file "$KUBELET_CONFIG" || exit 1
require_file "$CONTROLLER_MANAGER" || exit 1
require_file "$SCHEDULER" || exit 1

if [ "$(file_mode "$KUBELET_SERVICE")" = "600" ]; then
  pass "Are kubelet service file permissions set to 600?"
else
  fail "Are kubelet service file permissions set to 600?"
fi

if [ "$(file_mode "$KUBELET_CONFIG")" = "600" ]; then
  pass "Are kubelet config file permissions set to 600?"
else
  fail "Are kubelet config file permissions set to 600?"
fi

if [ -d "$ETCD_DIR" ] && [ "$(owner_group "$ETCD_DIR")" = "etcd:etcd" ]; then
  pass "Is the etcd data directory owned by etcd:etcd?"
else
  fail "Is the etcd data directory owned by etcd:etcd?"
fi

if grep -Eq '^[[:space:]]*-[[:space:]]*--profiling=false([[:space:]]*)?$' "$CONTROLLER_MANAGER" \
  && ! grep -Eq -- '--profiling=true' "$CONTROLLER_MANAGER"; then
  pass "Is kube-controller-manager profiling disabled?"
else
  fail "Is kube-controller-manager profiling disabled?"
fi

if grep -Eq '^[[:space:]]*-[[:space:]]*--profiling=false([[:space:]]*)?$' "$SCHEDULER" \
  && ! grep -Eq -- '--profiling=true' "$SCHEDULER"; then
  pass "Is kube-scheduler profiling disabled?"
else
  fail "Is kube-scheduler profiling disabled?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
