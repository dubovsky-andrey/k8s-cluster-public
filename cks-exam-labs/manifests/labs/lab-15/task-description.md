You need to enable auditing on this cluster. A basic policy file is available at `/etc/kubernetes/cluster-policy.yaml`.

The logs should be stored at `/var/log/cluster-audit.log`. The logs should be retained for `10 days` and should not exceed `10MB`. A maximum of `3` files should be kept at a time.

After you enable auditing on the cluster, update the basic policy file to track the following:

- delete activity on secrets in the `kube-system` namespace at the `Metadata` level;
- changes to deployments in the `default` namespace at the `Request` level;
- all other requests at the `Metadata` level.

Make sure your changes to the policy file are in effect.

A copy of the `kube-apiserver.yaml` is kept in `~/` so that you can revert if the configuration goes wrong. Make sure `kube-apiserver` is working fine for grading.

Validate your work with:

```bash
sh ~/val.sh
```
