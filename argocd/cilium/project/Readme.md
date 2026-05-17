To check lates Clilium gateway Api

```
curl -s https://api.github.com/repos/kubernetes-sigs/gateway-api/releases \
  | jq -r '.[].tag_name | select(test("^v[0-9]+\\.[0-9]+\\.[0-9]+$"))' \
  | head -n1
```