#!/bin/sh
set -eu

STATE=/run/cks/upgrade-state
TARGET=v1.35.2
OLD=v1.35.1

init_state() {
  mkdir -p "$STATE"
  [ -f "$STATE/worker_version" ] || printf '%s\n' "$OLD" > "$STATE/worker_version"
  [ -f "$STATE/master_version" ] || printf '%s\n' "$TARGET" > "$STATE/master_version"
  [ -f "$STATE/schedulable" ] || printf 'true\n' > "$STATE/schedulable"
  [ -f "$STATE/ready" ] || printf 'true\n' > "$STATE/ready"
  [ -f "$STATE/kubeadm_pkg" ] || printf '%s\n' "$OLD" > "$STATE/kubeadm_pkg"
  [ -f "$STATE/kubelet_pkg" ] || printf '%s\n' "$OLD" > "$STATE/kubelet_pkg"
  [ -f "$STATE/kubectl_pkg" ] || printf '%s\n' "$OLD" > "$STATE/kubectl_pkg"
  [ -f "$STATE/kubeadm_hold" ] || printf 'true\n' > "$STATE/kubeadm_hold"
  [ -f "$STATE/kubelet_hold" ] || printf 'true\n' > "$STATE/kubelet_hold"
  [ -f "$STATE/kubectl_hold" ] || printf 'true\n' > "$STATE/kubectl_hold"
}

read_state() {
  cat "$STATE/$1"
}

write_state() {
  printf '%s\n' "$2" > "$STATE/$1"
}

version_from_package() {
  case "$1" in
    *1.35.2*) printf '%s\n' "$TARGET" ;;
    *1.35.1*) printf '%s\n' "$OLD" ;;
    *) printf 'unsupported\n' ;;
  esac
}

cmd_kubectl() {
  case "${1:-}" in
    get)
      case "${2:-}" in
        nodes|node|no)
          if [ "${3:-}" = "worker-1" ]; then
            node_line worker-1
          else
            printf 'NAME       STATUS                     ROLES           AGE   VERSION\n'
            node_line master-1
            node_line worker-1
          fi
          ;;
        pods|pod|po)
          pod_lines "$@"
          ;;
        *)
          printf 'kubectl get: unsupported resource: %s\n' "${2:-}" >&2
          exit 1
          ;;
      esac
      ;;
    drain)
      [ "${1:-}" = "drain" ] || exit 1
      [ "${2:-}" = "worker-1" ] || { printf 'Only worker-1 should be drained\n' >&2; exit 1; }
      write_state schedulable false
      write_state ready false
      touch "$STATE/drained"
      printf 'node/worker-1 cordoned\n'
      printf 'node/worker-1 drained\n'
      ;;
    uncordon)
      [ "${2:-}" = "worker-1" ] || { printf 'Only worker-1 should be uncordoned\n' >&2; exit 1; }
      write_state schedulable true
      if [ "$(read_state worker_version)" = "$TARGET" ]; then
        write_state ready true
      fi
      touch "$STATE/uncordoned"
      printf 'node/worker-1 uncordoned\n'
      ;;
    version)
      printf 'Client Version: %s\n' "$(read_state kubectl_pkg)"
      printf 'Server Version: %s\n' "$(read_state master_version)"
      ;;
    *)
      printf 'kubectl: unsupported command: %s\n' "${1:-}" >&2
      exit 1
      ;;
  esac
}

node_line() {
  node="$1"
  if [ "$node" = "master-1" ]; then
    printf 'master-1   Ready                      control-plane   42d   %s\n' "$(read_state master_version)"
    return
  fi
  status=Ready
  [ "$(read_state ready)" = "true" ] || status=NotReady
  [ "$(read_state schedulable)" = "true" ] || status="${status},SchedulingDisabled"
  printf 'worker-1   %-25s <none>          42d   %s\n' "$status" "$(read_state worker_version)"
}

pod_lines() {
  all_namespaces=false
  for arg in "$@"; do
    [ "$arg" = "-A" ] || [ "$arg" = "--all-namespaces" ] && all_namespaces=true
  done

  if [ "$all_namespaces" = "true" ]; then
    printf 'NAMESPACE     NAME                                READY   STATUS    RESTARTS   AGE\n'
    printf 'kube-system   coredns-6f6b679f8f-mhz7x           1/1     Running   0          42d\n'
    printf 'kube-system   coredns-6f6b679f8f-xvk2r           1/1     Running   0          42d\n'
    printf 'kube-system   etcd-master-1                      1/1     Running   0          42d\n'
    printf 'kube-system   kube-apiserver-master-1            1/1     Running   0          42d\n'
    printf 'kube-system   kube-controller-manager-master-1   1/1     Running   0          42d\n'
    printf 'kube-system   kube-proxy-4f8k9                   1/1     Running   0          42d\n'
    printf 'kube-system   kube-proxy-cj7mz                   1/1     Running   0          42d\n'
    printf 'kube-system   kube-scheduler-master-1            1/1     Running   0          42d\n'
  else
    printf 'No resources found in default namespace.\n'
  fi
}

cmd_apt_mark() {
  action="${1:-}"
  shift || true
  case "$action" in
    hold|unhold)
      for pkg in "$@"; do
        case "$pkg" in
          kubeadm|kubelet|kubectl)
            [ "$action" = "hold" ] && write_state "${pkg}_hold" true || write_state "${pkg}_hold" false
            printf '%s set on hold.\n' "$pkg"
            ;;
          *) printf 'apt-mark: unsupported package: %s\n' "$pkg" >&2; exit 1 ;;
        esac
      done
      ;;
    showhold)
      for pkg in kubeadm kubelet kubectl; do
        [ "$(read_state "${pkg}_hold")" = "true" ] && printf '%s\n' "$pkg"
      done
      ;;
    *) printf 'apt-mark: unsupported action: %s\n' "$action" >&2; exit 1 ;;
  esac
}

cmd_apt_get() {
  case "${1:-}" in
    update)
      touch "$STATE/apt_updated"
      printf 'Package lists updated\n'
      ;;
    install)
      shift
      [ "${1:-}" = "-y" ] && shift
      for spec in "$@"; do
        pkg="${spec%%=*}"
        version="$(version_from_package "$spec")"
        [ "$version" = "$TARGET" ] || { printf 'E: Version not found for %s\n' "$pkg" >&2; exit 1; }
        [ "$(read_state "${pkg}_hold")" = "false" ] || { printf 'E: Held packages were changed and -y was used without --allow-change-held-packages.\n' >&2; exit 100; }
        case "$pkg" in
          kubeadm|kubelet|kubectl) write_state "${pkg}_pkg" "$TARGET"; printf 'Setting up %s (%s)\n' "$pkg" "$TARGET" ;;
          *) printf 'E: Unable to locate package %s\n' "$pkg" >&2; exit 1 ;;
        esac
      done
      ;;
    *) printf 'apt-get: unsupported command: %s\n' "${1:-}" >&2; exit 1 ;;
  esac
}

cmd_kubeadm() {
  case "${1:-} ${2:-}" in
    "version ")
      printf 'kubeadm version: &version.Info{GitVersion:"%s"}\n' "$(read_state kubeadm_pkg)"
      ;;
    "upgrade node")
      [ "$(read_state kubeadm_pkg)" = "$TARGET" ] || { printf '[upgrade] kubeadm must be upgraded first\n' >&2; exit 1; }
      touch "$STATE/kubeadm_node_upgraded"
      printf '[upgrade] Reading configuration from the cluster...\n'
      printf '[upgrade] The configuration for this node was successfully updated\n'
      ;;
    *)
      printf 'kubeadm: unsupported command\n' >&2
      exit 1
      ;;
  esac
}

cmd_systemctl() {
  case "${1:-}" in
    daemon-reload)
      touch "$STATE/daemon_reload"
      printf 'daemon-reload complete\n'
      ;;
    restart)
      [ "${2:-}" = "kubelet" ] || [ "${2:-}" = "kubelet.service" ] || { printf 'unsupported service\n' >&2; exit 1; }
      [ -f "$STATE/kubeadm_node_upgraded" ] || { printf 'kubelet refused to restart: kubeadm upgrade node was not run\n' >&2; exit 1; }
      [ "$(read_state kubelet_pkg)" = "$TARGET" ] || { printf 'kubelet package is still old\n' >&2; exit 1; }
      [ -f "$STATE/daemon_reload" ] || { printf 'systemd daemon-reload is required first\n' >&2; exit 1; }
      write_state worker_version "$TARGET"
      [ "$(read_state schedulable)" = "true" ] && write_state ready true || write_state ready false
      touch "$STATE/kubelet_restarted"
      printf 'restarted kubelet\n'
      ;;
    status)
      printf '%s is active (simulated)\n' "${2:-service}"
      ;;
    *) printf 'systemctl: unsupported action: %s\n' "${1:-}" >&2; exit 1 ;;
  esac
}

cmd_sudo() {
  exec "$@"
}

init_state
cmd="$(basename "$0")"
case "$cmd" in
  kubectl) cmd_kubectl "$@" ;;
  apt-mark) cmd_apt_mark "$@" ;;
  apt-get) cmd_apt_get "$@" ;;
  kubeadm) cmd_kubeadm "$@" ;;
  systemctl) cmd_systemctl "$@" ;;
  sudo) cmd_sudo "$@" ;;
  *) printf 'unsupported simulator entrypoint: %s\n' "$cmd" >&2; exit 1 ;;
esac
