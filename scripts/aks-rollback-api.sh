#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-rollback-api'

NAMESPACE="${K8S_NAMESPACE:-default}"
REVISION="${1:-}"

require_command kubectl
if [[ -n "$REVISION" && ! "$REVISION" =~ ^[1-9][0-9]*$ ]]; then
  log_error "Revision must be a positive integer."
  exit 2
fi

log_warn "Rolling back Dolly API in namespace $NAMESPACE${REVISION:+ to revision $REVISION}"
if [[ -n "$REVISION" ]]; then
  kubectl rollout undo --namespace "$NAMESPACE" deployment/dolly-api --to-revision="$REVISION"
else
  kubectl rollout undo --namespace "$NAMESPACE" deployment/dolly-api
fi
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="${ROLLOUT_TIMEOUT:-300s}"
