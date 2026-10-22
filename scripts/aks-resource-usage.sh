#!/usr/bin/env bash
# Script: aks-resource-usage.sh
# Version: 1.1.0
# Summary: Displays node, pod, and horizontal pod autoscaler resource information.
# Usage: aks-resource-usage.sh
# Inputs: Optional K8S_NAMESPACE environment variable; requires metrics-server for kubectl top.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-resource-usage'

SCRIPT_USAGE='Usage: aks-resource-usage.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"

require_command kubectl
log_info "Reading node and pod resource usage; this requires metrics-server"
kubectl top nodes
kubectl top pods --namespace "$NAMESPACE" --containers
kubectl get hpa --namespace "$NAMESPACE" -o wide --ignore-not-found
