#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-resource-usage'

NAMESPACE="${K8S_NAMESPACE:-default}"

require_command kubectl
log_info "Reading node and pod resource usage; this requires metrics-server"
kubectl top nodes
kubectl top pods --namespace "$NAMESPACE" --containers
kubectl get hpa --namespace "$NAMESPACE" -o wide --ignore-not-found
