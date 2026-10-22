#!/usr/bin/env bash
# Script: aks-rollout-history.sh
# Version: 1.1.0
# Summary: Displays deployment rollout history, optionally for one revision.
# Usage: aks-rollout-history.sh [deployment [revision]]
# Inputs: Optional deployment and positive revision; K8S_NAMESPACE environment variable.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-rollout-history'

SCRIPT_USAGE='Usage: aks-rollout-history.sh [deployment [revision]]'
handle_help "$@"
validate_arg_count 0 2 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
DEPLOYMENT="${1:-dolly-api}"
REVISION="${2:-}"

require_command kubectl
log_info "Reading rollout history for deployment $DEPLOYMENT in namespace $NAMESPACE"
if [[ -n "$REVISION" ]]; then
  validate_positive_integer REVISION "$REVISION"
  kubectl rollout history --namespace "$NAMESPACE" "deployment/$DEPLOYMENT" --revision="$REVISION"
else
  kubectl rollout history --namespace "$NAMESPACE" "deployment/$DEPLOYMENT"
fi
