# Task 02: Restrict frontend access with AppArmor and least privilege

You are connected to the `lab-02` Kubernetes cluster.

A pod has been created in the `omni` namespace, but it has a few issues that need to be addressed.

The pod has been created with more permissions than it needs. It also allows read access to the `/usr/share/nginx/html/internal` directory, making the Internal Site publicly accessible.

Use the recommendations below to resolve this:

- use the AppArmor profile named `restricted-frontend` to restrict access to the internal site;
- the profile file is prepared on the node at `/etc/apparmor.d/frontend`;
- apply the principle of least privilege and use the service account with the minimum privileges, excluding the `default` service account;
- once the pod is recreated with the correct service account, delete the other unused service accounts in the `omni` namespace, excluding the `default` service account;
- do not create a new service account;
- do not use the `default` service account.

Useful starting commands:

```bash
kubectl get pod frontend-site -n omni -o yaml
kubectl get sa -n omni
kubectl get role,rolebinding -n omni
kubectl auth can-i --list -n omni --as system:serviceaccount:omni:frontend-default
kubectl auth can-i --list -n omni --as system:serviceaccount:omni:frontend
kubectl auth can-i --list -n omni --as system:serviceaccount:omni:fe
```

Validate your answer:

```bash
sh ~/val.sh
```
