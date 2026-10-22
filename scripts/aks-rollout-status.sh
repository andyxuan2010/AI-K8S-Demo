#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-rollout-status'

NAMESPACE="${K8S_NAMESPACE:-default}"
DEPLOYMENT="${1:-dolly-api}"

require_command kubectl
log_info "Checking rollout status for deployment $DEPLOYMENT in namespace $NAMESPACE"
kubectl rollout status --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" --timeout="${ROLLOUT_TIMEOUT:-300s}"
kubectl get deployment,pods --namespace "$NAMESPACE" -o wide
