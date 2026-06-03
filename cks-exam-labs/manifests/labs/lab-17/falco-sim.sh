#!/bin/sh
set -eu

RULES=/etc/falco/falco_rules.local.yaml

while [ "$#" -gt 0 ]; do
  case "$1" in
    -r)
      shift
      RULES="${1:-$RULES}"
      ;;
  esac
  shift || true
done

if grep -q '/dev/mem' "$RULES" 2>/dev/null \
  && grep -q 'container.id' "$RULES" 2>/dev/null; then
  printf '08:21:42.000000000: Notice Shell (container_id=8b11devmem42)\n'
  exit 0
fi

printf 'Falco initialized with rules file %s\n' "$RULES"
printf 'No events matched. Check that your rule matches fd.name=/dev/mem and outputs %%container.id.\n'
