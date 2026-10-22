#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${K8S_NAMESPACE:-default}"
DEPLOYMENT="${1:-dolly-api}"

command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required." >&2; exit 1; }
kubectl rollout status --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" --timeout="${ROLLOUT_TIMEOUT:-300s}"
kubectl get deployment,pods --namespace "$NAMESPACE" -o wide
