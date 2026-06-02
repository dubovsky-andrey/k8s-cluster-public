Deployment `web-app` is running in the `products` namespace.

Database `product-db` is running in the `database` namespace.

Create a NetworkPolicy named `allow-traffic-to-products` in the `products` namespace.

Requirements:

- Allow ingress traffic from the `product-db` workload to the `web-app` workload.
- Allow all ingress traffic originating from the `payments` namespace to the `web-app` workload.
- Use the labels applied on the relevant resources.
- Do not allow other ingress sources to the `web-app` workload.

You can inspect the existing resources with `kubectl`.

Validate your work with:

```bash
sh ~/val.sh
```
