#!/bin/sh
set -eu

install -d -m 775 -o student -g student /var/lib/kubelet /etc/kubernetes/manifests /run/cks
install -m 664 -o student -g student /run/cks/kubelet-config.yaml /var/lib/kubelet/config.yaml
install -m 664 -o student -g student /run/cks/etcd.yaml /etc/kubernetes/manifests/etcd.yaml
rm -f /run/cks/systemd-daemon-reload /run/cks/kubelet-restarted

printf 'Task files reset:\n'
printf '  /var/lib/kubelet/config.yaml\n'
printf '  /etc/kubernetes/manifests/etcd.yaml\n'
