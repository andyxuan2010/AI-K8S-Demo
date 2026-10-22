#!/usr/bin/env bash
# Script: aks-port-forward-api.sh
# Version: 1.1.0
# Summary: Forwards a local TCP port to the Dolly API Kubernetes service.
# Usage: aks-port-forward-api.sh [local-port]
# Inputs: Optional local port; K8S_NAMESPACE, SERVICE_NAME, and SERVICE_PORT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-port-forward-api'

SCRIPT_USAGE='Usage: aks-port-forward-api.sh [local-port]'
handle_help "$@"
validate_arg_count 0 1 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
LOCAL_PORT="${1:-8000}"
SERVICE="${SERVICE_NAME:-dolly-api-service}"
SERVICE_PORT="${SERVICE_PORT:-8000}"

validate_positive_integer LOCAL_PORT "$LOCAL_PORT" false 65535
validate_positive_integer SERVICE_PORT "$SERVICE_PORT" false 65535
require_command kubectl

log_info "Forwarding localhost:$LOCAL_PORT to service/$SERVICE:$SERVICE_PORT in $NAMESPACE; press Ctrl-C to stop"
kubectl port-forward --namespace "$NAMESPACE" "service/$SERVICE" "$LOCAL_PORT:$SERVICE_PORT"
