# Task 04: TLS Secret

You are connected to the `lab-04` Kubernetes cluster.

Secure access to the existing web server using SSL files stored in a TLS Secret.

Create a TLS Secret named `clever-cactus` in the `clever-cactus` namespace for the existing Deployment named `clever-cactus`.

Use these SSL files:

- certificate: `/home/candidate/ca-cert/web.k8s.local.crt`;
- private key: `/home/candidate/ca-cert/web.k8s.local.key`.

Update the Deployment so the `web` container mounts the TLS Secret at `/etc/nginx/tls`.

Validate your answer:

sh ~/val.sh
