#!/bin/sh
set -u

target="all"
while [ "$#" -gt 0 ]; do
  case "$1" in
    --targets)
      shift
      target="${1:-all}"
      ;;
  esac
  shift || true
done

mode() {
  stat -c '%a' "$1" 2>/dev/null || printf missing
}

owner() {
  stat -c '%U:%G' "$1" 2>/dev/null || printf missing
}

check() {
  id="$1"
  status="$2"
  text="$3"
  remediation="$4"
  printf '[%s] %s %s\n' "$status" "$id" "$text"
  if [ "$status" = "FAIL" ]; then
    printf '      Remediation: %s\n' "$remediation"
  fi
}

run_node() {
  [ "$(mode /usr/lib/systemd/system/kubelet.service)" = "600" ] \
    && check 4.1.1 PASS "Ensure kubelet service file permissions are set to 600 or more restrictive" "" \
    || check 4.1.1 FAIL "Ensure kubelet service file permissions are set to 600 or more restrictive" "chmod 600 /usr/lib/systemd/system/kubelet.service"

  [ "$(mode /var/lib/kubelet/config.yaml)" = "600" ] \
    && check 4.1.9 PASS "Ensure kubelet config.yaml file permissions are set to 600 or more restrictive" "" \
    || check 4.1.9 FAIL "Ensure kubelet config.yaml file permissions are set to 600 or more restrictive" "chmod 600 /var/lib/kubelet/config.yaml"
}

run_master() {
  grep -Eq '^[[:space:]]*-[[:space:]]*--profiling=false([[:space:]]*)?$' /etc/kubernetes/manifests/kube-controller-manager.yaml 2>/dev/null \
    && ! grep -Eq -- '--profiling=true' /etc/kubernetes/manifests/kube-controller-manager.yaml 2>/dev/null \
    && check 1.3.2 PASS "Ensure that the --profiling argument is set to false for kube-controller-manager" "" \
    || check 1.3.2 FAIL "Ensure that the --profiling argument is set to false for kube-controller-manager" "Edit /etc/kubernetes/manifests/kube-controller-manager.yaml and set --profiling=false"

  grep -Eq '^[[:space:]]*-[[:space:]]*--profiling=false([[:space:]]*)?$' /etc/kubernetes/manifests/kube-scheduler.yaml 2>/dev/null \
    && ! grep -Eq -- '--profiling=true' /etc/kubernetes/manifests/kube-scheduler.yaml 2>/dev/null \
    && check 1.4.1 PASS "Ensure that the --profiling argument is set to false for kube-scheduler" "" \
    || check 1.4.1 FAIL "Ensure that the --profiling argument is set to false for kube-scheduler" "Edit /etc/kubernetes/manifests/kube-scheduler.yaml and set --profiling=false"

  [ "$(owner /var/lib/etcd)" = "etcd:etcd" ] \
    && check 1.1.12 PASS "Ensure that the etcd data directory ownership is set to etcd:etcd" "" \
    || check 1.1.12 FAIL "Ensure that the etcd data directory ownership is set to etcd:etcd" "chown -R etcd:etcd /var/lib/etcd"

  check 1.2.5 FAIL "Ensure that the --kubelet-client-certificate and --kubelet-client-key arguments are set as appropriate" "Do not fix this exception in this lab"
  check 5.2.1 WARN "Minimize admission of privileged containers by policy" "Ignored policy finding"
}

case "$target" in
  node)
    run_node
    ;;
  master)
    run_master
    ;;
  *)
    run_node
    run_master
    ;;
esac
