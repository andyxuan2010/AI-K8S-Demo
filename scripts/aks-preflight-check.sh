#!/usr/bin/env bash
# Script: aks-preflight-check.sh
# Version: 1.1.0
# Summary: Checks cluster access, namespace availability, and server-side manifest validation.
# Usage: aks-preflight-check.sh
# Inputs: Optional K8S_NAMESPACE environment variable.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-preflight-check'

SCRIPT_USAGE='Usage: aks-preflight-check.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
NAMESPACE="${K8S_NAMESPACE:-default}"
K8S_DIR="$REPO_ROOT/k8s"

require_command kubectl
log_info "Checking cluster connection and namespace $NAMESPACE"
kubectl config current-context
kubectl cluster-info
kubectl get namespace "$NAMESPACE" >/dev/null

for manifest in deployment.yaml service.yaml ingress.yaml; do
  log_info "Server-side validating $manifest"
  kubectl apply --dry-run=server --namespace "$NAMESPACE" -f "$K8S_DIR/$manifest"
done

log_info "AKS preflight checks passed"
