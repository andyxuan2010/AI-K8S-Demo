#!/usr/bin/env bash
# Script: aks-rollout-status.sh
# Version: 1.1.0
# Summary: Waits for a deployment rollout and lists its pods.
# Usage: aks-rollout-status.sh [deployment]
# Inputs: Optional deployment; K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-rollout-status'

SCRIPT_USAGE='Usage: aks-rollout-status.sh [deployment]'
handle_help "$@"
validate_arg_count 0 1 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
DEPLOYMENT="${1:-dolly-api}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_non_empty DEPLOYMENT "$DEPLOYMENT"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"

require_command kubectl
log_info "Checking rollout status for deployment $DEPLOYMENT in namespace $NAMESPACE"
kubectl rollout status --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" --timeout="$ROLLOUT_TIMEOUT"
kubectl get deployment,pods --namespace "$NAMESPACE" -o wide
