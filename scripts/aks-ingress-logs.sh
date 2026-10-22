#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-ingress-logs'

NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
DEPLOYMENT="${INGRESS_DEPLOYMENT:-ingress-nginx-controller}"
FOLLOW="${FOLLOW:-true}"
LOG_ARGS=(--namespace "$NAMESPACE" --all-containers=true --since="${SINCE:-30m}" --tail="${TAIL:-200}")

require_command kubectl
if [[ "$FOLLOW" == "true" ]]; then
  log_info "Following ingress controller logs in namespace $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}" --follow
else
  log_info "Showing recent ingress controller logs in namespace $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}"
fi
