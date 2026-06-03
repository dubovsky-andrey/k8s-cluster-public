#!/bin/sh
set -u

STATE=/run/cks/upgrade-state
TARGET=v1.35.2
OLD=v1.35.1

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

read_state() {
  cat "$STATE/$1" 2>/dev/null || true
}

if [ "$(read_state master_version)" = "$TARGET" ]; then
  pass "Is the control plane still on $TARGET?"
else
  fail "Is the control plane still on $TARGET?"
fi

if [ "$(read_state kubeadm_pkg)" = "$TARGET" ] && [ -f "$STATE/kubeadm_node_upgraded" ]; then
  pass "Was kubeadm upgraded and was kubeadm upgrade node run?"
else
  fail "Was kubeadm upgraded and was kubeadm upgrade node run?"
fi

if [ "$(read_state kubelet_pkg)" = "$TARGET" ] && [ "$(read_state kubectl_pkg)" = "$TARGET" ]; then
  pass "Were kubelet and kubectl upgraded?"
else
  fail "Were kubelet and kubectl upgraded?"
fi

if [ "$(read_state kubeadm_hold)" = "true" ] \
  && [ "$(read_state kubelet_hold)" = "true" ] \
  && [ "$(read_state kubectl_hold)" = "true" ]; then
  pass "Were Kubernetes packages placed back on hold?"
else
  fail "Were Kubernetes packages placed back on hold?"
fi

if [ -f "$STATE/drained" ]; then
  pass "Was worker-1 drained before maintenance?"
else
  fail "Was worker-1 drained before maintenance?"
fi

if [ -f "$STATE/daemon_reload" ] && [ -f "$STATE/kubelet_restarted" ]; then
  pass "Was systemd reloaded and kubelet restarted?"
else
  fail "Was systemd reloaded and kubelet restarted?"
fi

if [ "$(read_state worker_version)" = "$TARGET" ] && [ "$(read_state ready)" = "true" ]; then
  pass "Is worker-1 Ready on $TARGET?"
else
  fail "Is worker-1 Ready on $TARGET?"
fi

if [ "$(read_state schedulable)" = "true" ] && [ -f "$STATE/uncordoned" ]; then
  pass "Was worker-1 uncordoned?"
else
  fail "Was worker-1 uncordoned?"
fi

if [ "$(read_state worker_version)" != "$OLD" ]; then
  pass "Was the old version removed from worker-1?"
else
  fail "Was the old version removed from worker-1?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
