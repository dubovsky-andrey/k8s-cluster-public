#!/usr/bin/env bash
set -euo pipefail

LAB_HOST="${LAB_HOST:-192.168.1.190}"
KNOWN_HOSTS="${KNOWN_HOSTS:-$HOME/.ssh/known_hosts}"

# Add/remove labs here. Lab 02 maps to namespace cks-lab-02 and SSH port 32002.
LABS=(
  02
  03
  04
  05
  06
  07
)

# Add deployment names here if a lab gets more resettable deployments later.
DEPLOYMENTS=(
  cks-shell
)

remove_known_host() {
  local lab="$1"
  local port="320${lab}"

  if command -v ssh-keygen >/dev/null 2>&1 && [ -f "$KNOWN_HOSTS" ]; then
    ssh-keygen -f "$KNOWN_HOSTS" -R "[${LAB_HOST}]:${port}" >/dev/null 2>&1 || true
    printf '[lab-%s] known_hosts cleaned for %s:%s\n' "$lab" "$LAB_HOST" "$port"
  else
    printf '[lab-%s] known_hosts cleanup skipped\n' "$lab"
  fi
}

restart_deployment() {
  local namespace="$1"
  local deployment="$2"

  printf '[%s] restarting deployment/%s ...\n' "$namespace" "$deployment"
  kubectl -n "$namespace" rollout restart "deployment/${deployment}" |
    sed "s/^/[${namespace}] /"
}

for lab in "${LABS[@]}"; do
  namespace="cks-lab-${lab}"

  printf '\n== lab-%s (%s:%s) ==\n' "$lab" "$LAB_HOST" "320${lab}"
  remove_known_host "$lab"

  for deployment in "${DEPLOYMENTS[@]}"; do
    restart_deployment "$namespace" "$deployment"
  done
done
