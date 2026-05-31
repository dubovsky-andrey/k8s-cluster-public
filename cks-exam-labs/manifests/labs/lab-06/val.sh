#!/bin/sh
set -u

KUBELET_CONFIG=/var/lib/kubelet/config.yaml
ETCD_MANIFEST=/etc/kubernetes/manifests/etcd.yaml

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

field_value() {
  awk -v path="$1" '
    function trim(s) {
      sub(/^[[:space:]]+/, "", s)
      sub(/[[:space:]]+$/, "", s)
      return s
    }
    BEGIN {
      n = split(path, want, ".")
    }
    /^[[:space:]]*#/ || /^[[:space:]]*$/ { next }
    {
      indent = match($0, /[^ ]/) - 1
      level = int(indent / 2) + 1
      line = $0
      sub(/^[[:space:]]*/, "", line)
      key = line
      sub(/:.*/, "", key)
      key = trim(key)
      val = line
      sub(/^[^:]*:[[:space:]]*/, "", val)
      val = trim(val)
      stack[level] = key
      for (i = level + 1; i <= 20; i++) {
        stack[i] = ""
      }
      if (level == n) {
        ok = 1
        for (i = 1; i <= n; i++) {
          if (stack[i] != want[i]) {
            ok = 0
          }
        }
        if (ok) {
          print val
          exit
        }
      }
    }
  ' "$2"
}

if [ -f "$KUBELET_CONFIG" ]; then
  pass "Is the kubelet config present?"
else
  fail "Is the kubelet config present?"
  exit 1
fi

if [ -f "$ETCD_MANIFEST" ]; then
  pass "Is the etcd static pod manifest present?"
else
  fail "Is the etcd static pod manifest present?"
  exit 1
fi

anonymous_enabled="$(field_value authentication.anonymous.enabled "$KUBELET_CONFIG")"
webhook_auth_enabled="$(field_value authentication.webhook.enabled "$KUBELET_CONFIG")"
authorization_mode="$(field_value authorization.mode "$KUBELET_CONFIG")"

if [ "$anonymous_enabled" = "false" ]; then
  pass "Is anonymous kubelet authentication disabled?"
else
  fail "Is anonymous kubelet authentication disabled?"
fi

if [ "$webhook_auth_enabled" = "true" ]; then
  pass "Is kubelet Webhook authentication enabled?"
else
  fail "Is kubelet Webhook authentication enabled?"
fi

if [ "$authorization_mode" = "Webhook" ]; then
  pass "Is kubelet Webhook authorization enabled?"
else
  fail "Is kubelet Webhook authorization enabled?"
fi

if grep -Eq '^[[:space:]]*-[[:space:]]*--client-cert-auth=true([[:space:]]*)?$' "$ETCD_MANIFEST" \
  && ! grep -Eq -- '--client-cert-auth=false' "$ETCD_MANIFEST"; then
  pass "Does etcd require client certificate authentication?"
else
  fail "Does etcd require client certificate authentication?"
fi

if [ -f /run/cks/systemd-daemon-reload ] && [ -f /run/cks/kubelet-restarted ]; then
  pass "Were services reconfigured and kubelet restarted?"
else
  fail "Were services reconfigured and kubelet restarted?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
