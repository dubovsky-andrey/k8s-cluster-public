#!/bin/sh
set -eu

archive=""
output=""
format=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --image-archive)
      shift
      archive="${1:-}"
      ;;
    --format)
      shift
      format="${1:-}"
      ;;
    --output)
      shift
      output="${1:-}"
      ;;
  esac
  shift || true
done

if [ "$format" != "json" ]; then
  printf 'only --format json is supported in this lab\n' >&2
  exit 1
fi

if [ "$archive" != "/root/ImageTarballs/curlimages_curl_8.10.1.tar" ]; then
  printf 'unsupported image archive: %s\n' "$archive" >&2
  exit 1
fi

if [ -z "$output" ]; then
  printf 'missing --output\n' >&2
  exit 1
fi

cat > "$output" <<'EOF'
{
  "spdxVersion": "SPDX-2.3",
  "dataLicense": "CC0-1.0",
  "SPDXID": "SPDXRef-DOCUMENT",
  "name": "curlimages/curl:8.10.1",
  "documentNamespace": "https://cks.local/lab-09/curlimages-curl-8.10.1",
  "creationInfo": {
    "created": "2026-06-01T00:00:00Z",
    "creators": [
      "Tool: bom"
    ]
  },
  "packages": [
    {
      "name": "curlimages/curl:8.10.1",
      "SPDXID": "SPDXRef-Package-Image",
      "downloadLocation": "NOASSERTION",
      "filesAnalyzed": false
    },
    {
      "name": "curl",
      "SPDXID": "SPDXRef-Package-curl",
      "downloadLocation": "NOASSERTION",
      "filesAnalyzed": false,
      "versionInfo": "8.10.1"
    }
  ]
}
EOF
