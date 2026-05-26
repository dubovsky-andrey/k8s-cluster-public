# Task 02: Repair network isolation

You are connected to the `lab-02` Kubernetes cluster.

Find the unsafe network policy in namespace `task-02` and replace it with a restrictive policy.

Requirements:

- deny ingress by default;
- deny egress by default;
- allow only same-namespace traffic to the web workload on port 80;
- keep the workload running.

Useful starting commands:

```bash
kubectl get pods -A
kubectl get networkpolicy -n task-02
kubectl describe networkpolicy -n task-02
```
