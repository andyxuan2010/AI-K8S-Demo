#!/usr/bin/env bash
# Script: aks-watch-pods.sh
# Version: 1.1.0
# Summary: Watches pods in a Kubernetes namespace, optionally filtered by label selector.
# Usage: aks-watch-pods.sh
# Inputs: Optional K8S_NAMESPACE and POD_SELECTOR environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-watch-pods'

SCRIPT_USAGE='Usage: aks-watch-pods.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
SELECTOR="${POD_SELECTOR:-}"
if [[ -n "$SELECTOR" ]]; then
  validate_non_empty POD_SELECTOR "$SELECTOR"
fi

require_command kubectl
log_info "Watching pods in namespace $NAMESPACE${SELECTOR:+ matching $SELECTOR}; press Ctrl-C to stop"
if [[ -n "$SELECTOR" ]]; then
  kubectl get pods --namespace "$NAMESPACE" --selector "$SELECTOR" --watch --output wide
else
  kubectl get pods --namespace "$NAMESPACE" --watch --output wide
fi
