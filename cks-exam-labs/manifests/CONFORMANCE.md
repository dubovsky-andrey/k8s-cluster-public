# CKS exam lab conformance

Checked against the target model:

```text
1 lab = 1 vCluster = 1 SSH pod = 1 kubeconfig = 1 task
```

## Implemented

| Requirement | Status | Where |
| --- | --- | --- |
| ArgoCD manages labs | Done | root `cks-labs-root.yaml` |
| Dedicated root app deploys vClusters | Done | `cks-vclusters-root` includes `manifests/labs/*/vcluster-app.yaml` |
| Dedicated root app deploys SSH/task labs | Done | `cks-lab-shells-root` includes `manifests/labs/*/app.yaml` |
| Each lab has own host namespace | Done | `cks-lab-01`, `cks-lab-02`, `cks-lab-03` |
| Each lab has own vCluster | Done | `lab-01`, `lab-02`, `lab-03` Helm releases |
| Each lab has own SSH pod | Done | `manifests/labs/*/ssh-pod.yaml` |
| Each SSH pod mounts one kubeconfig | Done | `/home/student/.kube/config` from `vc-lab-XX` |
| Each lab has own SSH port | Done | `32001`, `32002`, `32003` |
| Task is mounted as `~/task.md` | Done | `manifests/labs/*/task-description.md` mounted through ConfigMap |
| Broken task env is created inside vCluster | Done | SSH pod initContainer runs `kubectl apply` with the lab kubeconfig |
| Local laptop requires only SSH | Done by design | `ACCESS.md` |
| Cluster skill has CKS lab policy | Done | `skills/references/cks-exam-lab-policy.md` |

## Runtime Checks Required

These need a live sync or image build:

| Check | Command |
| --- | --- |
| Shell image builds | `docker build -t ghcr.io/dubovsky-andrey/cks-shell:v0.1.0 cks-exam-labs/manifests/shared/cks-shell-image` |
| vCluster creates kubeconfig Secret | `kubectl -n cks-lab-01 get secret vc-lab-01` |
| SSH pod starts | `kubectl -n cks-lab-01 get pod -l app.kubernetes.io/name=cks-shell` |
| SSH access works | `ssh student@<HOST_IP> -p 32001` |
| kubectl works inside SSH | `kubectl get pods -A` |
| task file exists inside SSH | `cat ~/task.md` |

## Known Bootstrap Requirements

Before syncing:

- replace `REPLACE_WITH_YOUR_PUBLIC_KEY` in every lab `ssh-authorized-key-secret.yaml`;
- build and push `ghcr.io/dubovsky-andrey/cks-shell:v0.1.0`, or change the image name in every `ssh-pod.yaml`;
- confirm NodePorts `32001`, `32002`, `32003` are not already used.

The vCluster control plane uses non-persistent storage for these disposable labs:

```yaml
controlPlane:
  statefulSet:
    persistence:
      volumeClaim:
        enabled: false
```

This avoids requiring a default StorageClass or pre-created PVs. Deleting or recreating a vCluster resets that lab.

## Not Covered

These are intentionally out of scope for vCluster labs:

- kubelet config;
- containerd config;
- static pods on real nodes;
- etcd restore;
- systemd services;
- real `/etc/kubernetes` files;
- real node AppArmor/seccomp file management.

Use separate VM-based labs for those.
