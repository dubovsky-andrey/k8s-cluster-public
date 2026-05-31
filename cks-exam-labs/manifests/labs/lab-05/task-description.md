# Task 05: Dockerfile Security Best Practices

You are connected to the `lab-05` Kubernetes cluster.

Analyze and harden the provided Dockerfile located at `/cks/docker/Dockerfile`.

Resolve all prominent image security and best practice issues in the file.

Critical constraints:

- keep the Dockerfile in place;
- preserve the application purpose;
- prefer modifying existing configuration over replacing the file;
- if a non-privileged user is required for any operation, use UID `65535`.

Validate your answer:

sh ~/val.sh
