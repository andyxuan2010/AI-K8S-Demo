#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
IMAGE="${IMAGE:-andyxuan2010/dolly-api:v1.0}"

command -v docker >/dev/null 2>&1 || { echo "Docker is required." >&2; exit 1; }
docker build --tag "$IMAGE" "$REPO_ROOT/k8s"
docker push "$IMAGE"
