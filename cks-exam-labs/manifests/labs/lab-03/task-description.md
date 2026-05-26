# Task 03: Reduce excessive RBAC

You are connected to the `lab-03` Kubernetes cluster.

Find the service account with excessive namespace permissions and reduce it to the minimum permissions required to read Pods and Services.

Requirements:

- remove wildcard verbs;
- remove wildcard resources;
- allow read-only access to Pods and Services;
- keep the workload running with the same ServiceAccount.

Useful starting commands:

```bash
kubectl get pods -A
kubectl get role,rolebinding -n task-03
kubectl auth can-i --as=system:serviceaccount:task-03:reader '*' '*' -n task-03
```
