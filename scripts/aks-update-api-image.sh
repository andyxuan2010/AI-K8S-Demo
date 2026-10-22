#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-update-api-image'

NAMESPACE="${K8S_NAMESPACE:-default}"
IMAGE="${1:-}"
DEPLOYMENT="${DEPLOYMENT:-dolly-api}"
CONTAINER="${CONTAINER:-dolly-api}"

if [[ -z "$IMAGE" ]]; then
  log_error "Usage: $0 <registry/image:tag>"
  exit 2
fi
require_command kubectl

log_info "Updating container $CONTAINER in deployment $DEPLOYMENT to $IMAGE"
kubectl set image --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" "$CONTAINER=$IMAGE"
kubectl rollout status --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" --timeout="${ROLLOUT_TIMEOUT:-300s}"
