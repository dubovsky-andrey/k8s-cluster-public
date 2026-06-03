#!/bin/sh
set -u

FALCO=/etc/falco/falco.yaml
LOCAL=/etc/falco/falco_rules.local.yaml
DEFAULT=/etc/falco/falco_rules.yaml
LOG=/opt/security_incidents/alerts.log

has() {
  grep -q -- "$1" "$2" 2>/dev/null
}

falco_config_ok() {
  has 'file_output:' "$FALCO" &&
    has 'enabled: true' "$FALCO" &&
    has 'keep_alive: false' "$FALCO" &&
    has 'filename: /opt/security_incidents/alerts.log' "$FALCO"
}

local_rule_ok() {
  has 'rule: Write below binary dir' "$LOCAL" &&
    has 'priority: CRITICAL' "$LOCAL" &&
    has 'File below a known binary directory opened for writing (user_id=%user.uid file_updated=%fd.name command=%proc.cmdline)' "$LOCAL" &&
    has 'bin_dir' "$LOCAL" &&
    has 'evt.dir = <' "$LOCAL" &&
    has 'open_write' "$LOCAL"
}

default_rule_unchanged() {
  has 'priority: WARNING' "$DEFAULT" &&
    has 'user=%user.name file=%fd.name command=%proc.cmdline' "$DEFAULT"
}

restart_falco() {
  if falco_config_ok && local_rule_ok && default_rule_unchanged; then
    mkdir -p /opt/security_incidents /run/cks
    printf '2026-06-03T00:00:00Z: Critical File below a known binary directory opened for writing (user_id=0 file_updated=/bin/sleep command=tar -xmf - -C /bin)\n' > "$LOG"
    touch /run/cks/falco-reloaded
    printf 'restarted falco\n'
  else
    printf 'falco failed to load updated configuration\n' >&2
    exit 1
  fi
}

case "${1:-}" in
  restart)
    [ "${2:-}" = "falco" ] || [ "${2:-}" = "falco.service" ] || { printf 'unsupported service\n' >&2; exit 1; }
    restart_falco
    ;;
  reload)
    [ "${2:-}" = "falco" ] || [ "${2:-}" = "falco.service" ] || { printf 'unsupported service\n' >&2; exit 1; }
    restart_falco
    ;;
  status)
    [ -f /run/cks/falco-reloaded ] && printf 'falco is active (running)\n' || printf 'falco is active (running), pending reload\n'
    ;;
  *)
    printf 'systemctl: unsupported action: %s\n' "${1:-}" >&2
    exit 1
    ;;
esac
