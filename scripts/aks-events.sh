#!/usr/bin/env bash
# Script: aks-events.sh
# Version: 1.1.0
# Summary: Lists the most recent events in a Kubernetes namespace.
# Usage: aks-events.sh
# Inputs: Optional K8S_NAMESPACE and EVENT_LIMIT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-events'

SCRIPT_USAGE='Usage: aks-events.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
EVENT_LIMIT="${EVENT_LIMIT:-50}"
validate_positive_integer EVENT_LIMIT "$EVENT_LIMIT"

require_command kubectl
require_command tail
log_info "Showing the latest $EVENT_LIMIT events in namespace $NAMESPACE"
kubectl get events --namespace "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -n "$EVENT_LIMIT"
