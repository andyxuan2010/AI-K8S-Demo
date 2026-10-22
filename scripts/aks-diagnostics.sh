#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-diagnostics'

NAMESPACE="${K8S_NAMESPACE:-default}"
APP_LABEL="${APP_LABEL:-app=dolly-api}"
POD="${1:-}"

require_command kubectl
log_info "Collecting AKS diagnostics for namespace $NAMESPACE"
kubectl get nodes -o wide
kubectl get deployments,replicasets,pods,services,ingresses --namespace "$NAMESPACE" -o wide
kubectl get events --namespace "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -n 40
if [[ -n "$POD" ]]; then
  kubectl describe pod --namespace "$NAMESPACE" "$POD"
  kubectl logs --namespace "$NAMESPACE" "$POD" --all-containers=true --tail=200
else
  kubectl logs --namespace "$NAMESPACE" --selector "$APP_LABEL" --all-containers=true --tail=200 || true
fi
