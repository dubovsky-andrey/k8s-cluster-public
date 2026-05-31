# Task 08: Find credential exposure in manifests

You are connected to the `lab-08` Kubernetes cluster.

The Release Engineering Team has shared YAML manifests and Dockerfiles for review. These files are located under `/opt/course/`.

Perform a manual static analysis and identify possible security issues related to unwanted credential exposure.

Running processes as root is not a concern in this task.

Assume that all referenced files, folders, secrets, and volume mounts are present. Ignore syntax or logic errors.

Requirements:

- record the full paths of files containing issues in `/opt/course/security-issues.txt`;
- write one filename per line;
- include only files with unwanted credential exposure issues.

Validate your answer:

sh ~/val.sh
