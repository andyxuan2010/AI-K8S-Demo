#!/usr/bin/env bash
# Script: aks-build-push-image.sh
# Version: 1.1.0
# Summary: Builds and pushes the Dolly API container image.
# Usage: aks-build-push-image.sh
# Inputs: Optional IMAGE environment variable.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-build-push-image'

SCRIPT_USAGE='Usage: aks-build-push-image.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
IMAGE="${IMAGE:-andyxuan2010/dolly-api:v1.0}"
validate_non_empty IMAGE "$IMAGE"

require_command docker
log_info "Building and pushing image $IMAGE"
docker build --tag "$IMAGE" "$REPO_ROOT/k8s"
docker push "$IMAGE"
