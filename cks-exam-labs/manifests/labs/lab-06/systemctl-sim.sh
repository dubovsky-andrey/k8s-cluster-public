#!/bin/sh
set -eu

case "${1:-}" in
  daemon-reload)
    touch /run/cks/systemd-daemon-reload
    printf 'daemon-reload complete\n'
    ;;
  restart)
    if [ "${2:-}" = "kubelet" ] || [ "${2:-}" = "kubelet.service" ]; then
      touch /run/cks/kubelet-restarted
      printf 'restarted %s\n' "$2"
    else
      printf 'systemctl: unsupported service: %s\n' "${2:-}" >&2
      exit 1
    fi
    ;;
  status)
    printf '%s is active (simulated)\n' "${2:-service}"
    ;;
  *)
    printf 'systemctl: unsupported action: %s\n' "${1:-}" >&2
    exit 1
    ;;
esac
