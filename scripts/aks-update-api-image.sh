#!/usr/bin/env bash
# Script: aks-update-api-image.sh
# Version: 1.1.0
# Summary: Updates the Dolly API container image and waits for rollout.
# Usage: aks-update-api-image.sh <registry/image:tag>
# Inputs: Required image reference; optional K8S_NAMESPACE, DEPLOYMENT, CONTAINER, and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-update-api-image'

SCRIPT_USAGE='Usage: aks-update-api-image.sh <registry/image:tag>'
handle_help "$@"
validate_arg_count 1 1 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
IMAGE="${1:-}"
DEPLOYMENT="${DEPLOYMENT:-dolly-api}"
CONTAINER="${CONTAINER:-dolly-api}"

validate_non_empty IMAGE "$IMAGE"
validate_non_empty DEPLOYMENT "$DEPLOYMENT"
validate_non_empty CONTAINER "$CONTAINER"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"
require_command kubectl

log_info "Updating container $CONTAINER in deployment $DEPLOYMENT to $IMAGE"
kubectl set image --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" "$CONTAINER=$IMAGE"
kubectl rollout status --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" --timeout="$ROLLOUT_TIMEOUT"
