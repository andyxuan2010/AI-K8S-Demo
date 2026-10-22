#!/usr/bin/env bash
# Script: run.sh
# Version: 1.1.0
# Summary: Builds and pushes the Dolly API image, applies its manifests, and waits for rollout.
# Usage: run.sh
# Inputs: Optional IMAGE, PUBLISHED_IMAGE, and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
script_init '1.1.0' 'k8s-run'

SCRIPT_USAGE='Usage: run.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

IMAGE="${IMAGE:-dolly-api:v1.1}"
PUBLISHED_IMAGE="${PUBLISHED_IMAGE:-andyxuan2010/dolly-api:v1.1}"
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_non_empty IMAGE "$IMAGE"
validate_non_empty PUBLISHED_IMAGE "$PUBLISHED_IMAGE"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"

require_command docker
require_command kubectl

log_info "Building local image $IMAGE"
docker build --tag "$IMAGE" "$SCRIPT_DIR"
docker images "$IMAGE"

if [[ "$IMAGE" != "$PUBLISHED_IMAGE" ]]; then
  log_info "Tagging $IMAGE as $PUBLISHED_IMAGE"
  docker tag "$IMAGE" "$PUBLISHED_IMAGE"
fi

log_info "Pushing image $PUBLISHED_IMAGE"
docker push "$PUBLISHED_IMAGE"

log_info "Applying Dolly API deployment, service, and ingress manifests"
kubectl apply -f "$SCRIPT_DIR/deployment.yaml" -f "$SCRIPT_DIR/service.yaml" -f "$SCRIPT_DIR/ingress.yaml"
kubectl rollout status deployment/dolly-api --timeout="$ROLLOUT_TIMEOUT"
