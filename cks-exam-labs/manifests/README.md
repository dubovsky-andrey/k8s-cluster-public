# CKS exam labs

This is the exam-style CKS simulator layout.

The required model is:

```text
1 lab = 1 vCluster = 1 SSH pod = 1 kubeconfig = 1 task
```

Local workstation access is SSH-only:

```powershell
ssh student@<HOST_IP> -p 32001
```

The task text is printed automatically on SSH login. Inside the SSH session, validate with:

```bash
sh ~/val.sh
```

Do not use local `vcluster connect` or local `kubectl config use-context` for this lab style.

## Bootstrap

Apply the repository root CKS bootstrap app:

```text
cks-labs-root.yaml
```

`cks-labs-root` deploys the CKS AppProject and child root apps from:

```text
cks-exam-labs/project/*.yaml
cks-exam-labs/application/*.yaml
```

`cks-vclusters-root` deploys only vCluster applications:

```text
cks-exam-labs/manifests/labs/*/vcluster-app.yaml
```

`cks-lab-shells-root` deploys only SSH/task lab applications:

```text
cks-exam-labs/manifests/labs/*/app.yaml
```

Sync order:

```text
cks-labs-root.yaml -> cks-exam-labs AppProject -> cks-vclusters-root -> cks-lab-shells-root
```

## Before Sync

Set the SSH public key in each lab copy of the authorized key Secret:

```text
cks-exam-labs/manifests/labs/lab-01/ssh-authorized-key-secret.yaml
```

Replace the placeholder with your real public key.

The `cks-exam-labs/manifests/shared` directory contains the common source templates for future labs. The live lab keeps local copies so Kustomize can build with the default safe load restrictions.

Build and publish the shell image from the separate `k8s-ubuntu` repository:

```text
ghcr.io/dubovsky-andrey/k8s-ubuntu:24.04
```

Then update the image in each lab's `ssh-pod.yaml` if your registry is different:

```text
ghcr.io/dubovsky-andrey/k8s-ubuntu:24.04
```

## Access

See:

```text
cks-exam-labs/manifests/ACCESS.md
```

## Current Labs

```text
lab-01 -> ssh student@<HOST_IP> -p 32001
lab-02 -> ssh student@<HOST_IP> -p 32002
lab-03 -> ssh student@<HOST_IP> -p 32003
lab-04 -> ssh student@<HOST_IP> -p 32004
lab-05 -> ssh student@<HOST_IP> -p 32005
lab-06 -> ssh student@<HOST_IP> -p 32006
lab-07 -> ssh student@<HOST_IP> -p 32007
lab-08 -> ssh student@<HOST_IP> -p 32008
```

## Add A New Lab

Copy:

```text
cks-exam-labs/manifests/labs/lab-01
```

Change:

- lab name,
- namespace,
- SSH NodePort,
- vCluster release name,
- task description,
- task manifests.
