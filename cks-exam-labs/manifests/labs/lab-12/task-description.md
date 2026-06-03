You are connected to a Kubernetes administration host.

The cluster has two nodes:

- `master-1` is running Kubernetes `v1.35.2`.
- `worker-1` is running Kubernetes `v1.35.1`.

Upgrade `worker-1` so that it runs the same Kubernetes version as `master-1`.

Requirements:

- Upgrade only `worker-1`.
- Do not change the control plane node version.
- Return `worker-1` to `Ready` and schedulable state.
- Use the normal kubeadm worker-node upgrade flow.

Validate your work with:

```bash
sh ~/val.sh
```
