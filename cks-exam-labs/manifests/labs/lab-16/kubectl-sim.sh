#!/bin/sh
set -eu

if [ "${1:-}" = "get" ] && { [ "${2:-}" = "pods" ] || [ "${2:-}" = "pod" ] || [ "${2:-}" = "po" ]; }; then
  if [ "${3:-}" = "-A" ] || [ "${4:-}" = "-A" ] || [ "${3:-}" = "--all-namespaces" ] || [ "${4:-}" = "--all-namespaces" ]; then
    printf 'NAMESPACE     NAME                         READY   STATUS    RESTARTS   AGE\n'
    printf 'default       web-front-64c8c6b8b7-hg9nx   1/1     Running   0          18m\n'
    printf 'default       suspect-httpd                1/1     Running   0          18m\n'
    printf 'falco         falco-9ht4s                  1/1     Running   0          18m\n'
    return 0 2>/dev/null || exit 0
  fi
fi

if [ "${1:-}" = "describe" ] && { [ "${2:-}" = "pod" ] || [ "${2:-}" = "pods" ]; }; then
  printf 'Name:             suspect-httpd\n'
  printf 'Namespace:        default\n'
  printf 'Containers:\n'
  printf '  httpd:\n'
  printf '    Image:        httpd:2.4-alpine\n'
  return 0 2>/dev/null || exit 0
fi

printf 'kubectl simulator supports get pods -A and describe pod suspect-httpd\n' >&2
exit 1
