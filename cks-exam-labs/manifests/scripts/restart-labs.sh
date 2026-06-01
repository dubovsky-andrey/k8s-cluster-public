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

ROLLOUT_RESOURCES=(
  deployment
  statefulset
  daemonset
)

MAX_PARALLEL="${MAX_PARALLEL:-${#LABS[@]}}"

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

restart_resource() {
  local namespace="$1"
  local resource="$2"

  printf '[%s] restarting %s ...\n' "$namespace" "$resource"
  kubectl -n "$namespace" rollout restart "$resource" |
    sed "s/^/[${namespace}] /"
  kubectl -n "$namespace" rollout status "$resource" |
    sed "s/^/[${namespace}] /"
}

restart_namespace() {
  local namespace="$1"
  local kind resource
  local found=false

  for kind in "${ROLLOUT_RESOURCES[@]}"; do
    while IFS= read -r resource; do
      [ -n "$resource" ] || continue
      found=true
      restart_resource "$namespace" "$resource"
    done < <(kubectl -n "$namespace" get "$kind" -o name 2>/dev/null || true)
  done

  if [ "$found" = "false" ]; then
    printf '[%s] no rollout resources found\n' "$namespace"
  fi
}

wait_for_slot() {
  while [ "$(jobs -rp | wc -l)" -ge "$MAX_PARALLEL" ]; do
    sleep 1
  done
}

restart_lab() {
  local lab="$1"
  local namespace="cks-lab-${lab}"

  printf '\n== lab-%s rollout start ==\n' "$lab"
  restart_namespace "$namespace"
  printf '== lab-%s rollout done ==\n' "$lab"
}

failed=false

for lab in "${LABS[@]}"; do
  printf '\n== lab-%s (%s:%s) ==\n' "$lab" "$LAB_HOST" "320${lab}"
  remove_known_host "$lab"
done

printf '\nStarting lab rollouts with MAX_PARALLEL=%s\n' "$MAX_PARALLEL"

for lab in "${LABS[@]}"; do
  wait_for_slot
  restart_lab "$lab" &
done

for job in $(jobs -p); do
  if ! wait "$job"; then
    failed=true
  fi
done

for lab in "${LABS[@]}"; do
  add_known_host "$lab"
done

if [ "$failed" = "true" ]; then
  printf '\nOne or more lab rollouts failed.\n'
  exit 1
fi

printf '\nAll lab rollouts finished.\n'
