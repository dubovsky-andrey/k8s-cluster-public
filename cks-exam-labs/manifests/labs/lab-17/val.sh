#!/bin/sh
set -u

STATE=/run/cks/devmem-state
RULES=/etc/falco/falco_rules.local.yaml

failures=0

pass() { printf 'PASS: %s\n' "$1"; }
fail() { printf 'FAIL: %s\n' "$1"; failures=$((failures + 1)); }

if grep -q '/dev/mem' "$RULES" 2>/dev/null \
  && grep -q 'container.id' "$RULES" 2>/dev/null; then
  pass "Did you create a Falco rule that detects /dev/mem and reports container id?"
else
  fail "Did you create a Falco rule that detects /dev/mem and reports container id?"
fi

if [ -f "$STATE/ollama_tools" ] && [ "$(cat "$STATE/ollama_tools")" = "0" ]; then
  pass "Was the misbehaving ollama-tools deployment scaled to 0?"
else
  fail "Was the misbehaving ollama-tools deployment scaled to 0?"
fi

if [ "$(cat "$STATE/ollama_api" 2>/dev/null || printf 1)" = "1" ] \
  && [ "$(cat "$STATE/ollama_web" 2>/dev/null || printf 1)" = "1" ]; then
  pass "Were the other ollama deployments left unchanged?"
else
  fail "Were the other ollama deployments left unchanged?"
fi

if kubectl get deployments 2>/dev/null | grep -q '^ollama-tools[[:space:]]*0/0'; then
  pass "Does kubectl show ollama-tools scaled down?"
else
  fail "Does kubectl show ollama-tools scaled down?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
