#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-watch-pods'

NAMESPACE="${K8S_NAMESPACE:-default}"
SELECTOR="${POD_SELECTOR:-}"

require_command kubectl
log_info "Watching pods in namespace $NAMESPACE${SELECTOR:+ matching $SELECTOR}; press Ctrl-C to stop"
if [[ -n "$SELECTOR" ]]; then
  kubectl get pods --namespace "$NAMESPACE" --selector "$SELECTOR" --watch --output wide
else
  kubectl get pods --namespace "$NAMESPACE" --watch --output wide
fi
