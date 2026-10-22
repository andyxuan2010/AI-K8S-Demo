#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-restart-api'

NAMESPACE="${K8S_NAMESPACE:-default}"
require_command kubectl
log_info "Restarting Dolly API in namespace $NAMESPACE"
kubectl rollout restart --namespace "$NAMESPACE" deployment/dolly-api
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="${ROLLOUT_TIMEOUT:-300s}"
