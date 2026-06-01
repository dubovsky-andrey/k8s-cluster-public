# Task 07: Fix kube-bench FAIL findings

You are connected to the `lab-07` Kubernetes cluster.

Several kube-bench findings are failing on the node and control plane configuration.

Kube-bench is installed, and its config files are available under `/opt/kube-bench`.
Use the `cis-1.10` benchmark with the current Kubernetes version.

Requirements:

- fix kubelet service file permission issues;
- fix kubelet `config.yaml` permission issues;
- fix incorrect ownership of the `etcd` data directory;
- fix the incorrect `profiling` argument value for:
  - `kube-controller-manager`;
  - `kube-scheduler`.

Only fix issues reported with status `FAIL`, except issue number `1.2.5`.
Ignore policy-related issues.

Validate your answer:

sh ~/val.sh
