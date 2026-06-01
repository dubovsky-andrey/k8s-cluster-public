# Task 02: Expose a web service with Cilium Ingress

You are connected to the `lab-02` Kubernetes cluster.

The cluster uses Cilium for Ingress. A web application is already running in the `web` namespace.

The application container listens on port `8080`. The Service named `web-site` exposes it on port `80`.

Requirements:

- create an Ingress named `web-site` in the `web` namespace;
- use the Cilium Ingress class named `cilium`;
- route requests for host `web.site.local` and path `/` to Service `web-site` on port `80`;
- create a TLS Secret named `web-site-tls` in the `web` namespace using:
  - certificate: `/home/student/tls/web.site.local.crt`;
  - private key: `/home/student/tls/web.site.local.key`;
- configure the Ingress for TLS termination for host `web.site.local`;
- redirect HTTP requests to HTTPS;
- do not enable TLS passthrough.

Validate your answer:

sh ~/val.sh
