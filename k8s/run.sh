#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
source "$REPO_ROOT/scripts/lib/common.sh"
script_init '1.0.0' 'k8s-run'

IMAGE="${IMAGE:-dolly-api:v1.1}"
PUBLISHED_IMAGE="${PUBLISHED_IMAGE:-andyxuan2010/dolly-api:v1.1}"

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
kubectl rollout status deployment/dolly-api --timeout="${ROLLOUT_TIMEOUT:-300s}"
