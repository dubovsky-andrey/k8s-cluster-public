To check the lates version 

```
helm show chart metrics-server \
  --repo https://kubernetes-sigs.github.io/metrics-server/ \
  | yq -r .version
```