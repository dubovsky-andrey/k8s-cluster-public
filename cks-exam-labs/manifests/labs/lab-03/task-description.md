# Task 03: Container Security Context

You are connected to the `lab-03` Kubernetes cluster.

Update the existing Deployment named `secdep` in the `sec-ns` namespace to ensure immutability of its containers.

Modify all containers in the Deployment so that they:

- use user ID `30000`;
- use a read-only root filesystem;
- prevent privilege escalation.

You can find the Deployment manifest file at:

```bash
~/sec-ns_deployment.yaml
```

Useful starting commands:

```bash
kubectl get deployment secdep -n sec-ns -o yaml
vi ~/sec-ns_deployment.yaml
kubectl apply -f ~/sec-ns_deployment.yaml
```

Validate your answer:

```bash
sh ~/val.sh
```
