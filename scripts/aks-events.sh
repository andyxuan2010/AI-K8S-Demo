#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-events'

NAMESPACE="${K8S_NAMESPACE:-default}"
EVENT_LIMIT="${EVENT_LIMIT:-50}"
if [[ ! "$EVENT_LIMIT" =~ ^[1-9][0-9]*$ ]]; then
  log_error "EVENT_LIMIT must be a positive integer."
  exit 2
fi

require_command kubectl
require_command tail
log_info "Showing the latest $EVENT_LIMIT events in namespace $NAMESPACE"
kubectl get events --namespace "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -n "$EVENT_LIMIT"
