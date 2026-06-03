#!/bin/sh
set -eu

if [ "${1:-}" = "ps" ]; then
  printf 'CONTAINER           IMAGE               CREATED          STATE      NAME      ATTEMPT   POD ID              POD\n'
  printf '8b11devmem42        6f3b6735e4d8        18 minutes ago   Running    ollama    0         pod-ollama-tools    ollama-tools-7dfc9d7f49-r7h2m\n'
  printf '379c0ffee912        6f3b6735e4d8        18 minutes ago   Running    ollama    0         pod-ollama-api      ollama-api-57df5f7bc5-bk9kp\n'
  printf '9a77beef1001        6f3b6735e4d8        18 minutes ago   Running    ollama    0         pod-ollama-web      ollama-web-66b6fdc665-tcl8q\n'
  exit 0
fi

printf 'crictl simulator supports crictl ps\n' >&2
exit 1
