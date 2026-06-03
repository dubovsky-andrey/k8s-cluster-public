#!/bin/sh
set -eu

API=/etc/kubernetes/manifests/kube-apiserver.yaml
POLICY=/etc/kubernetes/cluster-policy.yaml
LOG=/var/log/cluster-audit.log

has() {
  grep -q -- "$1" "$2" 2>/dev/null
}

apiserver_ok() {
  has '--audit-policy-file=/etc/kubernetes/cluster-policy.yaml' "$API" &&
    has '--audit-log-path=/var/log/cluster-audit.log' "$API" &&
    has '--audit-log-maxage=10' "$API" &&
    has '--audit-log-maxbackup=3' "$API" &&
    has '--audit-log-maxsize=10' "$API" &&
    has 'mountPath: /etc/kubernetes/cluster-policy.yaml' "$API" &&
    has 'mountPath: /var/log' "$API" &&
    has 'name: audit-policy' "$API" &&
    has 'name: varlog' "$API" &&
    has 'path: /etc/kubernetes/cluster-policy.yaml' "$API" &&
    has 'path: /var/log' "$API" &&
    has 'type: File' "$API" &&
    has 'type: Directory' "$API"
}

policy_ok() {
  has 'apiVersion: audit.k8s.io/v1' "$POLICY" &&
    has 'kind: Policy' "$POLICY" &&
    has 'RequestReceived' "$POLICY" &&
    has 'delete' "$POLICY" &&
    has 'secrets' "$POLICY" &&
    has 'kube-system' "$POLICY" &&
    has 'level: Request' "$POLICY" &&
    has 'create' "$POLICY" &&
    has 'update' "$POLICY" &&
    has 'patch' "$POLICY" &&
    has 'apps' "$POLICY" &&
    has 'deployments' "$POLICY" &&
    has 'default' "$POLICY"
}

if [ "${1:-}" = "get" ] && { [ "${2:-}" = "pods" ] || [ "${2:-}" = "pod" ] || [ "${2:-}" = "po" ]; }; then
  if apiserver_ok && policy_ok; then
    mkdir -p /var/log
    : > "$LOG"
    printf 'NAME                                      READY   STATUS    RESTARTS   AGE\n'
    printf 'coredns-6f6b679f8f-mhz7x                 1/1     Running   0          30d\n'
    printf 'etcd-controlplane                        1/1     Running   0          30d\n'
    printf 'kube-apiserver-controlplane              1/1     Running   0          30d\n'
    printf 'kube-controller-manager-controlplane     1/1     Running   0          30d\n'
    printf 'kube-scheduler-controlplane              1/1     Running   0          30d\n'
  else
    printf 'NAME                                      READY   STATUS             RESTARTS   AGE\n'
    printf 'kube-apiserver-controlplane              0/1     CrashLoopBackOff   4          2m\n'
  fi
  exit 0
fi

printf 'kubectl simulator supports: kubectl get pods -n kube-system\n' >&2
exit 1
