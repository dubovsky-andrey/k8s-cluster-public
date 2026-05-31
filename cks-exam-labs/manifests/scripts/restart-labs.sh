#!/usr/bin/env bash
set -euo pipefail

LAB_HOST="${LAB_HOST:-192.168.1.190}"
KNOWN_HOSTS="${KNOWN_HOSTS:-$HOME/.ssh/known_hosts}"

# Add/remove labs here. Lab 02 maps to namespace cks-lab-02 and SSH port 32002.
LABS=(
  01
  02
  03
  04
  05
  06
  07
  08
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

add_known_host() {
  local lab="$1"
  local port="320${lab}"
  local attempt

  if ! command -v ssh-keyscan >/dev/null 2>&1; then
    printf '[lab-%s] known_hosts add skipped: ssh-keyscan not found\n' "$lab"
    return
  fi

  mkdir -p "$(dirname "$KNOWN_HOSTS")"
  touch "$KNOWN_HOSTS"

  for attempt in 1 2 3 4 5; do
    if ssh-keyscan -T 5 -p "$port" "$LAB_HOST" >>"$KNOWN_HOSTS" 2>/dev/null; then
      printf '[lab-%s] known_hosts added for %s:%s\n' "$lab" "$LAB_HOST" "$port"
      return
    fi
    sleep 1
  done

  printf '[lab-%s] known_hosts add failed for %s:%s; continuing\n' "$lab" "$LAB_HOST" "$port"
}

restart_deployment() {
  local namespace="$1"
  local deployment="$2"

  printf '[%s] restarting deployment/%s ...\n' "$namespace" "$deployment"
  kubectl -n "$namespace" rollout restart "deployment/${deployment}" |
    sed "s/^/[${namespace}] /"
  kubectl -n "$namespace" rollout status "deployment/${deployment}" |
    sed "s/^/[${namespace}] /"
}

for lab in "${LABS[@]}"; do
  namespace="cks-lab-${lab}"

  printf '\n== lab-%s (%s:%s) ==\n' "$lab" "$LAB_HOST" "320${lab}"
  remove_known_host "$lab"

  for deployment in "${DEPLOYMENTS[@]}"; do
    restart_deployment "$namespace" "$deployment"
  done

  add_known_host "$lab"
done
