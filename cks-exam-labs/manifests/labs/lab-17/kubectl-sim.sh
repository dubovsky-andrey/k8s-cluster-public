#!/bin/sh
set -eu

STATE=/run/cks/devmem-state
mkdir -p "$STATE"
[ -f "$STATE/ollama_api" ] || printf '1\n' > "$STATE/ollama_api"
[ -f "$STATE/ollama_web" ] || printf '1\n' > "$STATE/ollama_web"
[ -f "$STATE/ollama_tools" ] || printf '1\n' > "$STATE/ollama_tools"

replicas() {
  cat "$STATE/$1"
}

get_deployments() {
  printf 'NAME           READY   UP-TO-DATE   AVAILABLE   AGE\n'
  printf 'ollama-api     %s/%s     %s            %s           18m\n' "$(replicas ollama_api)" "$(replicas ollama_api)" "$(replicas ollama_api)" "$(replicas ollama_api)"
  printf 'ollama-web     %s/%s     %s            %s           18m\n' "$(replicas ollama_web)" "$(replicas ollama_web)" "$(replicas ollama_web)" "$(replicas ollama_web)"
  printf 'ollama-tools   %s/%s     %s            %s           18m\n' "$(replicas ollama_tools)" "$(replicas ollama_tools)" "$(replicas ollama_tools)" "$(replicas ollama_tools)"
}

get_pods() {
  printf 'NAME                             READY   STATUS    RESTARTS   AGE\n'
  [ "$(replicas ollama_api)" = "0" ] || printf 'ollama-api-57df5f7bc5-bk9kp      1/1     Running   0          18m\n'
  [ "$(replicas ollama_web)" = "0" ] || printf 'ollama-web-66b6fdc665-tcl8q      1/1     Running   0          18m\n'
  [ "$(replicas ollama_tools)" = "0" ] || printf 'ollama-tools-7dfc9d7f49-r7h2m    1/1     Running   0          18m\n'
}

case "${1:-}" in
  get)
    case "${2:-}" in
      deployment|deployments|deploy)
        get_deployments
        ;;
      pods|pod|po)
        get_pods
        ;;
      *)
        printf 'kubectl get: unsupported resource: %s\n' "${2:-}" >&2
        exit 1
        ;;
    esac
    ;;
  scale)
    target="${2:-}"
    replicas_arg="${3:-}"
    case "$target" in
      deployment/ollama-api|deploy/ollama-api) file=ollama_api ;;
      deployment/ollama-web|deploy/ollama-web) file=ollama_web ;;
      deployment/ollama-tools|deploy/ollama-tools) file=ollama_tools ;;
      *) printf 'deployment not found: %s\n' "$target" >&2; exit 1 ;;
    esac
    case "$replicas_arg" in
      --replicas=*) desired="${replicas_arg#--replicas=}" ;;
      *) printf 'scale requires --replicas=N\n' >&2; exit 1 ;;
    esac
    printf '%s\n' "$desired" > "$STATE/$file"
    printf 'deployment.apps/%s scaled\n' "${target#*/}"
    ;;
  *)
    printf 'kubectl simulator supports get deployments, get pods, and scale deployment/<name> --replicas=N\n' >&2
    exit 1
    ;;
esac
