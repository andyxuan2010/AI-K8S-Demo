#!/usr/bin/env bash
# Script: aks-install-ingress.sh
# Version: 1.1.0
# Summary: Installs ingress-nginx and waits for its controller rollout.
# Usage: aks-install-ingress.sh
# Inputs: Optional INGRESS_NGINX_MANIFEST_URL and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-install-ingress'

SCRIPT_USAGE='Usage: aks-install-ingress.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

# Override with INGRESS_NGINX_MANIFEST_URL to pin a different controller release.
MANIFEST_URL="${INGRESS_NGINX_MANIFEST_URL:-https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml}"
validate_non_empty INGRESS_NGINX_MANIFEST_URL "$MANIFEST_URL"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"
require_command kubectl
log_info "Applying ingress-nginx manifest: $MANIFEST_URL"
kubectl apply -f "$MANIFEST_URL"
kubectl rollout status --namespace ingress-nginx deployment/ingress-nginx-controller --timeout="$ROLLOUT_TIMEOUT"
