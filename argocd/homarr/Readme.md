# Homarr

Homarr requires a stable encryption key. Create it outside this public repo:

```bash
kubectl create namespace homarr --dry-run=client -o yaml | kubectl apply -f -
kubectl -n homarr create secret generic homarr-secret \
  --from-literal=SECRET_ENCRYPTION_KEY="$(openssl rand -hex 32)"
```
