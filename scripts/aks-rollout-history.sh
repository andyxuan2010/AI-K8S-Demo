#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-rollout-history'

NAMESPACE="${K8S_NAMESPACE:-default}"
DEPLOYMENT="${1:-dolly-api}"
REVISION="${2:-}"

require_command kubectl
log_info "Reading rollout history for deployment $DEPLOYMENT in namespace $NAMESPACE"
if [[ -n "$REVISION" ]]; then
  if [[ ! "$REVISION" =~ ^[1-9][0-9]*$ ]]; then
    log_error "Revision must be a positive integer."
    exit 2
  fi
  kubectl rollout history --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" --revision="$REVISION"
else
  kubectl rollout history --namespace "$NAMESPACE" "deployment/$DEPLOYMENT"
fi
