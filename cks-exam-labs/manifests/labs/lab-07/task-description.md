# Task 07: Move a secret out of environment variables

You are connected to the `lab-07` Kubernetes cluster.

A pod has been created in the `orion` namespace. It uses a secret as an environment variable.

Requirements:

- extract the decoded value of `CONNECTOR_PASSWORD` from the running pod and write it to `/root/CKS/secrets/CONNECTOR_PASSWORD`;
- stop using `CONNECTOR_PASSWORD` as an environment variable in the pod;
- mount the existing secret as a read-only volume at `/mnt/connector/password`;
- keep the pod name `app-xyz` and the namespace `orion`.

Validate your answer:

sh ~/val.sh
