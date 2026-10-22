#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-port-forward-api'

NAMESPACE="${K8S_NAMESPACE:-default}"
LOCAL_PORT="${1:-8000}"
SERVICE="${SERVICE_NAME:-dolly-api-service}"
SERVICE_PORT="${SERVICE_PORT:-8000}"

if [[ ! "$LOCAL_PORT" =~ ^[1-9][0-9]*$ || ! "$SERVICE_PORT" =~ ^[1-9][0-9]*$ ]]; then
  log_error "Ports must be positive integers. Usage: $0 [local-port]"
  exit 2
fi
require_command kubectl

log_info "Forwarding localhost:$LOCAL_PORT to service/$SERVICE:$SERVICE_PORT in $NAMESPACE; press Ctrl-C to stop"
kubectl port-forward --namespace "$NAMESPACE" "service/$SERVICE" "$LOCAL_PORT:$SERVICE_PORT"
