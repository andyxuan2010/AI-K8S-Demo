#!/usr/bin/env bash
set -euo pipefail

# Override with INGRESS_NGINX_MANIFEST_URL to pin a different controller release.
MANIFEST_URL="${INGRESS_NGINX_MANIFEST_URL:-https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml}"
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required." >&2; exit 1; }
kubectl apply -f "$MANIFEST_URL"
kubectl rollout status --namespace ingress-nginx deployment/ingress-nginx-controller --timeout="${ROLLOUT_TIMEOUT:-300s}"
