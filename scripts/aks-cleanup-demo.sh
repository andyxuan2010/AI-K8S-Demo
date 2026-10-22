#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
K8S_DIR="$REPO_ROOT/k8s"
NAMESPACE="${K8S_NAMESPACE:-default}"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required." >&2; exit 1; }
kubectl delete --namespace "$NAMESPACE" -f "$K8S_DIR/ingress.yaml" -f "$K8S_DIR/service.yaml" -f "$K8S_DIR/deployment.yaml" --ignore-not-found
kubectl delete --namespace "$NAMESPACE" -f "$K8S_DIR/nginx-ingress.yaml" -f "$K8S_DIR/nginx-service.yaml" -f "$K8S_DIR/nginx-deployment.yaml" --ignore-not-found
