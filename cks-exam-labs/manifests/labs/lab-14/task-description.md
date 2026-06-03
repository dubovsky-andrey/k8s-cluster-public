Edit the `gamma` deployment in the `galaxy` namespace to ensure that all containers meet the following requirements:

- run as user `1001`;
- do not allow privilege escalation;
- mount their file systems as read-only.

Do not change the deployment's replicas, labels, selector, container names, images, commands, or ports.

Validate your work with:

```bash
sh ~/val.sh
```
