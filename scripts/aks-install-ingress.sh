#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-install-ingress'

# Override with INGRESS_NGINX_MANIFEST_URL to pin a different controller release.
MANIFEST_URL="${INGRESS_NGINX_MANIFEST_URL:-https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml}"
require_command kubectl
log_info "Applying ingress-nginx manifest: $MANIFEST_URL"
kubectl apply -f "$MANIFEST_URL"
kubectl rollout status --namespace ingress-nginx deployment/ingress-nginx-controller --timeout="${ROLLOUT_TIMEOUT:-300s}"
