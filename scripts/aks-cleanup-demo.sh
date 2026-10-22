#!/usr/bin/env bash
# Script: aks-cleanup-demo.sh
# Version: 1.1.0
# Summary: Deletes Dolly API and demo NGINX resources from the selected namespace.
# Usage: aks-cleanup-demo.sh
# Inputs: Optional K8S_NAMESPACE environment variable.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-cleanup-demo'

SCRIPT_USAGE='Usage: aks-cleanup-demo.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
K8S_DIR="$REPO_ROOT/k8s"
NAMESPACE="${K8S_NAMESPACE:-default}"

require_command kubectl
log_warn "Deleting Dolly API and demo NGINX resources from namespace $NAMESPACE"
kubectl delete --namespace "$NAMESPACE" -f "$K8S_DIR/ingress.yaml" -f "$K8S_DIR/service.yaml" -f "$K8S_DIR/deployment.yaml" --ignore-not-found
kubectl delete --namespace "$NAMESPACE" -f "$K8S_DIR/nginx-ingress.yaml" -f "$K8S_DIR/nginx-service.yaml" -f "$K8S_DIR/nginx-deployment.yaml" --ignore-not-found
