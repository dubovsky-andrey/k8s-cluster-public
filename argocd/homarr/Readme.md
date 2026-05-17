# Homarr

Homarr requires a stable database encryption key. Create it outside this public repo:

```bash
kubectl create namespace homarr --dry-run=client -o yaml | kubectl apply -f -
kubectl -n homarr create secret generic db-encryption \
  --from-literal=db-encryption-key="$(openssl rand -hex 32)"
```

Check the latest stable Homarr release in one command:

```bash
curl -s https://api.github.com/repos/homarr-labs/homarr/releases/latest | jq -r .tag_name
```

Check the latest Homarr Helm chart version in one command:

```bash
helm show chart homarr --repo https://homarr-labs.github.io/charts/ | yq -r .version
```
