#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="${K8S_NAMESPACE:-default}"
REPLICAS="${1:-}"
if [[ ! "$REPLICAS" =~ ^[0-9]+$ ]]; then
  echo "Usage: $0 <non-negative-replica-count>" >&2
  exit 2
fi
command -v kubectl >/dev/null 2>&1 || { echo "kubectl is required." >&2; exit 1; }
kubectl scale --namespace "$NAMESPACE" deployment/dolly-api --replicas="$REPLICAS"
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="${ROLLOUT_TIMEOUT:-300s}"
