# Task 06: Secure kubelet and etcd

You are connected to the `lab-06` Kubernetes cluster.

Fix the security issues in the kubelet and etcd configuration.

Files to inspect and remediate:

- `/var/lib/kubelet/config.yaml`
- `/etc/kubernetes/manifests/etcd.yaml`

Requirements:

- disable anonymous kubelet authentication;
- use Webhook authentication and authorization for kubelet;
- ensure etcd requires client certificate authentication;
- reconfigure/restart services so the changed settings take effect;
- keep the existing files in place.

Validate your answer:

sh ~/val.sh
