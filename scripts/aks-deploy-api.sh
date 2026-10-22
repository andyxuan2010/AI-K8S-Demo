#!/usr/bin/env bash
# Script: aks-deploy-api.sh
# Version: 1.1.0
# Summary: Applies Dolly API manifests and waits for deployment rollout.
# Usage: aks-deploy-api.sh
# Inputs: Optional K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-deploy-api'

SCRIPT_USAGE='Usage: aks-deploy-api.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
K8S_DIR="$REPO_ROOT/k8s"
NAMESPACE="${K8S_NAMESPACE:-default}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"

require_command kubectl
log_info "Applying Dolly API manifests to namespace $NAMESPACE"
kubectl apply --namespace "$NAMESPACE" -f "$K8S_DIR/deployment.yaml" -f "$K8S_DIR/service.yaml" -f "$K8S_DIR/ingress.yaml"
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="$ROLLOUT_TIMEOUT"
