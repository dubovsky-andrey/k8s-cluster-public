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

section() {
  printf '\n== %s ==\n' "$1"
}

check() {
  id="$1"
  status="$2"
  text="$3"
  remediation="$4"
  total=$((total + 1))
  case "$status" in
    PASS) pass_count=$((pass_count + 1)) ;;
    FAIL) fail_count=$((fail_count + 1)) ;;
    WARN) warn_count=$((warn_count + 1)) ;;
    INFO) info_count=$((info_count + 1)) ;;
  esac
  printf '[%s] %s %s\n' "$status" "$id" "$text"
  if [ "$status" = "FAIL" ]; then
    printf '      Remediation: %s\n' "$remediation"
  fi
}

summary() {
  printf '\n== Summary ==\n'
  printf '%s checks ran: %s PASS, %s FAIL, %s WARN, %s INFO\n' "$total" "$pass_count" "$fail_count" "$warn_count" "$info_count"
}

run_node() {
  section "4 Worker Node Security Configuration"
  check 4.1.0 INFO "Worker node file permission checks" ""
  [ "$(mode /usr/lib/systemd/system/kubelet.service)" = "600" ] \
    && check 4.1.1 PASS "Ensure kubelet service file permissions are set to 600 or more restrictive" "" \
    || check 4.1.1 FAIL "Ensure kubelet service file permissions are set to 600 or more restrictive" "chmod 600 /usr/lib/systemd/system/kubelet.service"

  [ "$(owner /usr/lib/systemd/system/kubelet.service)" = "root:root" ] \
    && check 4.1.2 PASS "Ensure kubelet service file ownership is set to root:root" "" \
    || check 4.1.2 WARN "Ensure kubelet service file ownership is set to root:root" ""

  check 4.1.3 PASS "Ensure proxy kubeconfig file permissions are set to 600 or more restrictive" ""
  check 4.1.4 PASS "Ensure proxy kubeconfig file ownership is set to root:root" ""
  check 4.1.5 PASS "Ensure kubelet.conf file permissions are set to 600 or more restrictive" ""
  check 4.1.6 PASS "Ensure kubelet.conf file ownership is set to root:root" ""
  check 4.1.7 PASS "Ensure certificate authorities file permissions are set to 600 or more restrictive" ""
  check 4.1.8 PASS "Ensure client certificate authorities file ownership is set to root:root" ""

  [ "$(mode /var/lib/kubelet/config.yaml)" = "600" ] \
    && check 4.1.9 PASS "Ensure kubelet config.yaml file permissions are set to 600 or more restrictive" "" \
    || check 4.1.9 FAIL "Ensure kubelet config.yaml file permissions are set to 600 or more restrictive" "chmod 600 /var/lib/kubelet/config.yaml"

  [ "$(owner /var/lib/kubelet/config.yaml)" = "root:root" ] \
    && check 4.1.10 PASS "Ensure kubelet config.yaml file ownership is set to root:root" "" \
    || check 4.1.10 WARN "Ensure kubelet config.yaml file ownership is set to root:root" ""

  section "4.2 Kubelet"
  check 4.2.1 PASS "Ensure that the anonymous-auth argument is set to false" ""
  check 4.2.2 PASS "Ensure that the authorization-mode argument is not set to AlwaysAllow" ""
  check 4.2.3 PASS "Ensure that the client-ca-file argument is set as appropriate" ""
  check 4.2.4 WARN "Verify that the read-only-port argument is set to 0" ""
  check 4.2.5 PASS "Ensure that the streaming-connection-idle-timeout argument is not set to 0" ""
}

run_master() {
  section "1 Control Plane Security Configuration"
  check 1.1.1 PASS "Ensure API server pod specification file permissions are set to 600 or more restrictive" ""
  check 1.1.2 PASS "Ensure API server pod specification file ownership is set to root:root" ""
  check 1.1.3 PASS "Ensure controller manager pod specification file permissions are set to 600 or more restrictive" ""
  check 1.1.4 PASS "Ensure controller manager pod specification file ownership is set to root:root" ""
  check 1.1.5 PASS "Ensure scheduler pod specification file permissions are set to 600 or more restrictive" ""
  check 1.1.6 PASS "Ensure scheduler pod specification file ownership is set to root:root" ""

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

total=0
pass_count=0
fail_count=0
warn_count=0
info_count=0

printf 'kube-bench simulated results for benchmark cis-1.10\n'
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
summary
