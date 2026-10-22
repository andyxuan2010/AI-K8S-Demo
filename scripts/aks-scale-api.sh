#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-scale-api'

NAMESPACE="${K8S_NAMESPACE:-default}"
REPLICAS="${1:-}"
if [[ ! "$REPLICAS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <non-negative-replica-count>" >&2
  exit 2
fi
require_command kubectl
log_info "Scaling Dolly API to $REPLICAS replicas in namespace $NAMESPACE"
kubectl scale --namespace "$NAMESPACE" deployment/dolly-api --replicas="$REPLICAS"
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="${ROLLOUT_TIMEOUT:-300s}"
