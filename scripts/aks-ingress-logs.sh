#!/usr/bin/env bash
# Script: aks-ingress-logs.sh
# Version: 1.1.0
# Summary: Displays or follows logs from the ingress controller deployment.
# Usage: aks-ingress-logs.sh
# Inputs: Optional INGRESS_NAMESPACE, INGRESS_DEPLOYMENT, FOLLOW, SINCE, and TAIL environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-ingress-logs'

SCRIPT_USAGE='Usage: aks-ingress-logs.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

NAMESPACE="${INGRESS_NAMESPACE:-ingress-nginx}"
DEPLOYMENT="${INGRESS_DEPLOYMENT:-ingress-nginx-controller}"
FOLLOW="${FOLLOW:-true}"
SINCE="${SINCE:-30m}"
TAIL="${TAIL:-200}"
validate_boolean FOLLOW "$FOLLOW"
validate_duration SINCE "$SINCE"
validate_positive_integer TAIL "$TAIL"
LOG_ARGS=(--namespace "$NAMESPACE" --all-containers=true --since="$SINCE" --tail="$TAIL")

require_command kubectl
if [[ "$FOLLOW" == "true" ]]; then
  log_info "Following ingress controller logs in namespace $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}" --follow
else
  log_info "Showing recent ingress controller logs in namespace $NAMESPACE"
  kubectl logs "deployment/$DEPLOYMENT" "${LOG_ARGS[@]}"
fi
