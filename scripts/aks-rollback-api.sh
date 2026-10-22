#!/usr/bin/env bash
# Script: aks-rollback-api.sh
# Version: 1.1.0
# Summary: Rolls back the Dolly API deployment to its previous or selected revision.
# Usage: aks-rollback-api.sh [revision]
# Inputs: Optional positive revision; K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-rollback-api'

SCRIPT_USAGE='Usage: aks-rollback-api.sh [revision]'
handle_help "$@"
validate_arg_count 0 1 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
REVISION="${1:-}"

require_command kubectl
if [[ -n "$REVISION" ]]; then
  validate_positive_integer REVISION "$REVISION"
fi
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"

log_warn "Rolling back Dolly API in namespace $NAMESPACE${REVISION:+ to revision $REVISION}"
if [[ -n "$REVISION" ]]; then
  kubectl rollout undo --namespace "$NAMESPACE" deployment/dolly-api --to-revision="$REVISION"
else
  kubectl rollout undo --namespace "$NAMESPACE" deployment/dolly-api
fi
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="$ROLLOUT_TIMEOUT"
