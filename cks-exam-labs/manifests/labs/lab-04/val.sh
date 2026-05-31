#!/bin/sh
set -u

NS=clever-cactus
DEPLOYMENT=clever-cactus
SECRET=clever-cactus
CRT=/home/candidate/ca-cert/web.k8s.local.crt
KEY=/home/candidate/ca-cert/web.k8s.local.key

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

encode_file() {
  base64 "$1" | tr -d '\n\r'
}

get_secret_jsonpath() {
  kubectl -n "$NS" get secret "$SECRET" -o "jsonpath=$1" 2>/dev/null
}

get_deploy_jsonpath() {
  kubectl -n "$NS" get deployment "$DEPLOYMENT" -o "jsonpath=$1" 2>/dev/null
}

if [ -f "$CRT" ] && [ -f "$KEY" ]; then
  pass "Are the certificate files available?"
else
  fail "Are the certificate files available?"
fi

if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  fail "Does namespace $NS exist?"
  exit 1
fi

if kubectl -n "$NS" get secret "$SECRET" >/dev/null 2>&1; then
  pass "Does the TLS Secret exist?"
else
  fail "Does the TLS Secret exist?"
fi

secret_type="$(get_secret_jsonpath '{.type}')"
if [ "$secret_type" = "kubernetes.io/tls" ]; then
  pass "Is the Secret a TLS Secret?"
else
  fail "Is the Secret a TLS Secret?"
fi

secret_crt="$(get_secret_jsonpath '{.data.tls\.crt}')"
secret_key="$(get_secret_jsonpath '{.data.tls\.key}')"
expected_crt=""
expected_key=""
if [ -f "$CRT" ]; then
  expected_crt="$(encode_file "$CRT")"
fi
if [ -f "$KEY" ]; then
  expected_key="$(encode_file "$KEY")"
fi

if [ -n "$secret_crt" ] && [ -n "$secret_key" ] \
  && [ "$secret_crt" = "$expected_crt" ] \
  && [ "$secret_key" = "$expected_key" ]; then
  pass "Does the Secret contain the required certificate and key?"
else
  fail "Does the Secret contain the required certificate and key?"
fi

if ! kubectl -n "$NS" get deployment "$DEPLOYMENT" >/dev/null 2>&1; then
  fail "Does deployment $DEPLOYMENT exist?"
  exit 1
fi

secret_refs="$(get_deploy_jsonpath '{.spec.template.spec.volumes[*].secret.secretName}')"
if printf ' %s ' "$secret_refs" | grep -q " $SECRET "; then
  pass "Is the Deployment configured to use the TLS Secret?"
else
  fail "Is the Deployment configured to use the TLS Secret?"
fi

mount_count="$(
  kubectl -n "$NS" get deployment "$DEPLOYMENT" -o json 2>/dev/null |
  jq --arg secret "$SECRET" '
    [.spec.template.spec.volumes[]?
      | select(.secret.secretName == $secret)
      | .name] as $tlsVolumes
    | [.spec.template.spec.containers[]?
      | select(.name == "web")
      | .volumeMounts[]?
      | select((.name as $name | $tlsVolumes | index($name)) and .mountPath == "/etc/nginx/tls")]
    | length
  ' 2>/dev/null || printf '0'
)"
if [ "$mount_count" -gt 0 ]; then
  pass "Is the TLS Secret mounted into the web container?"
else
  fail "Is the TLS Secret mounted into the web container?"
fi

desired="$(get_deploy_jsonpath '{.spec.replicas}')"
ready="$(get_deploy_jsonpath '{.status.readyReplicas}')"
if [ "${ready:-0}" = "${desired:-1}" ]; then
  pass "Is the Deployment ready?"
else
  fail "Is the Deployment ready?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
