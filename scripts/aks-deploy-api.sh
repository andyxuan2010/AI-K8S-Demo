#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-deploy-api'

REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
K8S_DIR="$REPO_ROOT/k8s"
NAMESPACE="${K8S_NAMESPACE:-default}"

require_command kubectl
log_info "Applying Dolly API manifests to namespace $NAMESPACE"
kubectl apply --namespace "$NAMESPACE" -f "$K8S_DIR/deployment.yaml" -f "$K8S_DIR/service.yaml" -f "$K8S_DIR/ingress.yaml"
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="${ROLLOUT_TIMEOUT:-300s}"
