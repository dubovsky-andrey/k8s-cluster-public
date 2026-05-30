# Task 01: Harden an unsafe workload

You are connected to the `lab-01` Kubernetes cluster.

Find and fix the unsafe workload in namespace `task-01`.

Requirements:

- the workload must not run as privileged;
- the container must not run as root;
- privilege escalation must be disabled;
- the service account must not have wildcard RBAC access;
- default network access must not allow all ingress and egress;
- keep the web application reachable inside the namespace.

Validate your answer:

sh ~/val.sh
