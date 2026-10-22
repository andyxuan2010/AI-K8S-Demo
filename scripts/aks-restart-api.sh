#!/usr/bin/env bash
# Script: aks-restart-api.sh
# Version: 1.1.0
# Summary: Restarts the Dolly API deployment and waits for rollout.
# Usage: aks-restart-api.sh
# Inputs: Optional K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-restart-api'

SCRIPT_USAGE='Usage: aks-restart-api.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"
require_command kubectl
log_info "Restarting Dolly API in namespace $NAMESPACE"
kubectl rollout restart --namespace "$NAMESPACE" deployment/dolly-api
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="$ROLLOUT_TIMEOUT"
