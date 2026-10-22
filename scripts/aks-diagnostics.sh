#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${K8S_NAMESPACE:-default}"
APP_LABEL="${APP_LABEL:-app=dolly-api}"
POD="${1:-}"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required." >&2; exit 1; }
kubectl get nodes -o wide
kubectl get deployments,replicasets,pods,services,ingresses --namespace "$NAMESPACE" -o wide
kubectl get events --namespace "$NAMESPACE" --sort-by=.metadata.creationTimestamp | tail -n 40
if [[ -n "$POD" ]]; then
  kubectl describe pod --namespace "$NAMESPACE" "$POD"
  kubectl logs --namespace "$NAMESPACE" "$POD" --all-containers=true --tail=200
else
  kubectl logs --namespace "$NAMESPACE" --selector "$APP_LABEL" --all-containers=true --tail=200 || true
fi
