#!/bin/sh
set -u

NS=web
INGRESS=web-site
SERVICE=web-site
SECRET=web-site-tls
HOST=web.site.local

failures=0

pass() {
  printf 'PASS: %s\n' "$1"
}

fail() {
  printf 'FAIL: %s\n' "$1"
  failures=$((failures + 1))
}

get_jsonpath() {
  kubectl -n "$NS" get ingress "$INGRESS" -o "jsonpath=$1" 2>/dev/null
}

if ! kubectl get namespace "$NS" >/dev/null 2>&1; then
  fail "Does the web namespace exist?"
  exit 1
fi

if kubectl get ingressclass cilium -o jsonpath='{.spec.controller}' 2>/dev/null | grep -Fxq 'io.cilium/ingress-controller'; then
  pass "Is the Cilium Ingress class available?"
else
  fail "Is the Cilium Ingress class available?"
fi

if kubectl -n kube-system get pod -l k8s-app=cilium 2>/dev/null | grep -q 'Running'; then
  pass "Are the Cilium lab components running?"
else
  fail "Are the Cilium lab components running?"
fi

ready_replicas="$(kubectl -n "$NS" get deploy "$SERVICE" -o jsonpath='{.status.readyReplicas}' 2>/dev/null || true)"
if [ "$ready_replicas" = "1" ]; then
  pass "Is the web Deployment ready?"
else
  fail "Is the web Deployment ready?"
fi

svc_port="$(kubectl -n "$NS" get svc "$SERVICE" -o jsonpath='{.spec.ports[?(@.name=="http")].port}' 2>/dev/null || true)"
svc_target="$(kubectl -n "$NS" get svc "$SERVICE" -o jsonpath='{.spec.ports[?(@.name=="http")].targetPort}' 2>/dev/null || true)"

if [ "$svc_port" = "80" ] && [ "$svc_target" = "8080" ]; then
  pass "Does the Service expose port 80 to container port 8080?"
else
  fail "Does the Service expose port 80 to container port 8080?"
fi

if kubectl -n "$NS" get secret "$SECRET" >/dev/null 2>&1; then
  secret_type="$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.type}' 2>/dev/null)"
  crt="$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.tls\.crt}' 2>/dev/null)"
  key="$(kubectl -n "$NS" get secret "$SECRET" -o jsonpath='{.data.tls\.key}' 2>/dev/null)"
  if [ "$secret_type" = "kubernetes.io/tls" ] && [ -n "$crt" ] && [ -n "$key" ]; then
    pass "Is the TLS Secret present?"
  else
    fail "Is the TLS Secret present?"
  fi
else
  fail "Is the TLS Secret present?"
fi

if ! kubectl -n "$NS" get ingress "$INGRESS" >/dev/null 2>&1; then
  fail "Does the Ingress exist?"
  printf '\n%s check(s) failed.\n' "$failures"
  exit 1
fi

class_name="$(get_jsonpath '{.spec.ingressClassName}')"
legacy_class="$(get_jsonpath '{.metadata.annotations.kubernetes\.io/ingress\.class}')"
if [ "$class_name" = "cilium" ] || [ "$legacy_class" = "cilium" ]; then
  pass "Does the Ingress use the Cilium class?"
else
  fail "Does the Ingress use the Cilium class?"
fi

backend_name="$(get_jsonpath '{.spec.rules[?(@.host=="web.site.local")].http.paths[?(@.path=="/")].backend.service.name}')"
backend_port="$(get_jsonpath '{.spec.rules[?(@.host=="web.site.local")].http.paths[?(@.path=="/")].backend.service.port.number}')"
path_type="$(get_jsonpath '{.spec.rules[?(@.host=="web.site.local")].http.paths[?(@.path=="/")].pathType}')"

if [ "$backend_name" = "$SERVICE" ] && [ "$backend_port" = "80" ] && [ "$path_type" = "Prefix" ]; then
  pass "Does the Ingress route web.site.local/ to Service port 80?"
else
  fail "Does the Ingress route web.site.local/ to Service port 80?"
fi

tls_secret="$(get_jsonpath '{.spec.tls[?(@.secretName=="web-site-tls")].secretName}')"
tls_host="$(get_jsonpath '{.spec.tls[?(@.secretName=="web-site-tls")].hosts[0]}')"

if [ "$tls_secret" = "$SECRET" ] && [ "$tls_host" = "$HOST" ]; then
  pass "Does the Ingress terminate TLS for web.site.local?"
else
  fail "Does the Ingress terminate TLS for web.site.local?"
fi

force_https="$(get_jsonpath '{.metadata.annotations.ingress\.cilium\.io/force-https}')"
tls_passthrough="$(get_jsonpath '{.metadata.annotations.ingress\.cilium\.io/tls-passthrough}')"

if [ "$force_https" = "enabled" ] && [ "$tls_passthrough" != "enabled" ]; then
  pass "Does the Ingress redirect HTTP to HTTPS without TLS passthrough?"
else
  fail "Does the Ingress redirect HTTP to HTTPS without TLS passthrough?"
fi

if [ "$failures" -eq 0 ]; then
  printf '\nAll checks passed.\n'
  exit 0
fi

printf '\n%s check(s) failed.\n' "$failures"
exit 1
