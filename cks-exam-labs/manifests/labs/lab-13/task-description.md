A workload named `sweeper` is running in the `automated` namespace.

Create a ServiceAccount named `bot-sa` in the `automated` namespace. Make sure that this ServiceAccount does not get automatically mounted to workloads.

Update the `sweeper` deployment:

- use the new `bot-sa` ServiceAccount;
- prevent automatic ServiceAccount token mounting;
- mount the ServiceAccount token manually as a projected volume at `/var/run/secrets/tokens/bot-token`;
- use token audience `default`;
- use token expiration `3600`;
- do not change any other fields in the deployment.

Validate your work with:

```bash
sh ~/val.sh
```
