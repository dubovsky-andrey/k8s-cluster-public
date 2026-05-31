# Task 05: Dockerfile Security Best Practices

You are connected to the `lab-05` Kubernetes cluster.

Analyze and edit the provided Dockerfile located at `/cks/docker/Dockerfile`.

Fix one instruction in the file that violates prominent security and best practice standards.

Analyze and edit the provided manifest file located at `/cks/docker/deployment.yaml`.

Fix one field in the file that violates prominent security and best practice standards.

Critical constraints:

- do not add or delete any configuration settings;
- only modify existing configurations to resolve security and best practice issues;
- if a non-privileged user is required for any operation, use UID `65535`.

Validate your answer:

sh ~/val.sh
