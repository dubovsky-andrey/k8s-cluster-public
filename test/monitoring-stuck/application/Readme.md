to check lates version

```
helm show chart kube-prometheus-stack \
  --repo https://prometheus-community.github.io/helm-charts \
  | yq -r .version
```