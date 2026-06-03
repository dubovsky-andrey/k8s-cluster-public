A misbehaving Pod is posing a security threat to the system.

Identify the misbehaving Pod belonging to the `ollama` application that is directly accessing system memory by reading from the sensitive file `/dev/mem`.

Scale down the Deployment of the identified misbehaving Pod to zero replicas.

Critical constraints:

- do not modify any other aspects of the Deployment;
- do not alter any other Deployments;
- do not delete any Deployments.

You can use Falco and the existing `/etc/falco/falco_rules.local.yaml` file to detect access to `/dev/mem`.

Validate your work with:

```bash
sh ~/val.sh
```
