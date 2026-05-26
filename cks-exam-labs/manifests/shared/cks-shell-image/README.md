# CKS shell image

Build and push this image before syncing exam labs.

Example:

```bash
docker build -t ghcr.io/dubovsky-andrey/cks-shell:v0.1.0 .
docker push ghcr.io/dubovsky-andrey/cks-shell:v0.1.0
```

The image is intentionally tool-heavy so the SSH session feels close to an exam terminal.
