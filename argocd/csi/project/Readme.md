To check latest version 

```
helm show chart csi-driver-smb \
  --repo https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts | yq -r .version
```