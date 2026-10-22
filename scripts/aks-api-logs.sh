#!/usr/bin/env bash
# Script: aks-api-logs.sh
# Version: 1.1.0
# Summary: Displays or follows logs from a Kubernetes deployment.
# Usage: aks-api-logs.sh [deployment]
# Inputs: Optional deployment name; K8S_NAMESPACE, FOLLOW, SINCE, and TAIL.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-api-logs'

SCRIPT_USAGE='Usage: aks-api-logs.sh [deployment]'
handle_help "$@"
validate_arg_count 0 1 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
DEPLOYMENT="${1:-dolly-api}"
FOLLOW="${FOLLOW:-true}"
SINCE="${SINCE:-30m}"
TAIL="${TAIL:-200}"
validate_boolean FOLLOW "$FOLLOW"
validate_duration SINCE "$SINCE"
validate_positive_integer TAIL "$TAIL"
LOG_ARGS=(--namespace "$NAMESPACE" --all-containers=true --since="$SINCE" --tail="$TAIL")

require_command kubectl
if [[ "$FOLLOW" == "true" ]]; then
  log_info "Following recent logs for deployment $DEPLOYMENT in $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}" --follow
else
  log_info "Showing recent logs for deployment $DEPLOYMENT in $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}"
fi
