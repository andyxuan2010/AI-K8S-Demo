#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-api-logs'

NAMESPACE="${K8S_NAMESPACE:-default}"
DEPLOYMENT="${1:-dolly-api}"
FOLLOW="${FOLLOW:-true}"
LOG_ARGS=(--namespace "$NAMESPACE" --all-containers=true --since="${SINCE:-30m}" --tail="${TAIL:-200}")

require_command kubectl
if [[ "$FOLLOW" == "true" ]]; then
  log_info "Following recent logs for deployment $DEPLOYMENT in $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}" --follow
else
  log_info "Showing recent logs for deployment $DEPLOYMENT in $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}"
fi
