#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-build-push-image'

REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
IMAGE="${IMAGE:-andyxuan2010/dolly-api:v1.0}"

require_command docker
log_info "Building and pushing image $IMAGE"
docker build --tag "$IMAGE" "$REPO_ROOT/k8s"
docker push "$IMAGE"
