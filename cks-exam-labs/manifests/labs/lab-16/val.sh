#!/bin/sh
set -u

FALCO=/etc/falco/falco.yaml
DEFAULT=/etc/falco/falco_rules.yaml
LOCAL=/etc/falco/falco_rules.local.yaml
LOG=/opt/security_incidents/alerts.log

failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }
has() { grep -q -- "$1" "$2" 2>/dev/null; }

if has 'file_output:' "$FALCO" \
  && has 'enabled: true' "$FALCO" \
  && has 'keep_alive: false' "$FALCO" \
  && has 'filename: /opt/security_incidents/alerts.log' "$FALCO"; then
  pass "Is Falco file output configured for /opt/security_incidents/alerts.log?"
else
  fail "Is Falco file output configured for /opt/security_incidents/alerts.log?"
fi

if has 'priority: WARNING' "$DEFAULT" \
  && has 'user=%user.name file=%fd.name command=%proc.cmdline' "$DEFAULT"; then
  pass "Is the default Falco rules file unchanged?"
else
  fail "Is the default Falco rules file unchanged?"
fi

if has 'rule: Write below binary dir' "$LOCAL" \
  && has 'priority: CRITICAL' "$LOCAL" \
  && has 'File below a known binary directory opened for writing (user_id=%user.uid file_updated=%fd.name command=%proc.cmdline)' "$LOCAL"; then
  pass "Does falco_rules.local.yaml override the target rule priority and output?"
else
  fail "Does falco_rules.local.yaml override the target rule priority and output?"
fi

if has 'bin_dir' "$LOCAL" \
  && has 'evt.dir = <' "$LOCAL" \
  && has 'open_write' "$LOCAL" \
  && has 'not package_mgmt_procs' "$LOCAL" \
  && has 'not user_known_write_below_binary_dir_activities' "$LOCAL"; then
  pass "Does the local override preserve the target rule condition?"
else
  fail "Does the local override preserve the target rule condition?"
fi

if [ -f /run/cks/falco-reloaded ]; then
  pass "Was Falco reloaded or restarted after configuration?"
else
  fail "Was Falco reloaded or restarted after configuration?"
fi

if [ -f "$LOG" ] \
  && grep -q 'Critical File below a known binary directory opened for writing (user_id=0 file_updated=/bin/sleep command=tar -xmf - -C /bin)' "$LOG"; then
  pass "Did Falco write the expected alert to /opt/security_incidents/alerts.log?"
else
  fail "Did Falco write the expected alert to /opt/security_incidents/alerts.log?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
