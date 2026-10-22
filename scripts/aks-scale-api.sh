#!/usr/bin/env bash
# Script: aks-scale-api.sh
# Version: 1.1.0
# Summary: Scales the Dolly API deployment to the requested replica count.
# Usage: aks-scale-api.sh <replica-count>
# Inputs: Required non-negative replica count; optional K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-scale-api'

SCRIPT_USAGE='Usage: aks-scale-api.sh <replica-count>'
handle_help "$@"
validate_arg_count 1 1 "$@"

NAMESPACE="${K8S_NAMESPACE:-default}"
REPLICAS="${1:-}"
validate_positive_integer REPLICAS "$REPLICAS" true
ROLLOUT_TIMEOUT="${ROLLOUT_TIMEOUT:-300s}"
validate_duration ROLLOUT_TIMEOUT "$ROLLOUT_TIMEOUT"
require_command kubectl
log_info "Scaling Dolly API to $REPLICAS replicas in namespace $NAMESPACE"
kubectl scale --namespace "$NAMESPACE" deployment/dolly-api --replicas="$REPLICAS"
kubectl rollout status --namespace "$NAMESPACE" deployment/dolly-api --timeout="$ROLLOUT_TIMEOUT"
