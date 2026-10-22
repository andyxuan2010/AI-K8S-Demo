#!/usr/bin/env bash
# Script: aks-connect.sh
# Version: 1.1.0
# Summary: Fetches AKS credentials and displays cluster status.
# Usage: aks-connect.sh
# Inputs: Optional AZURE_RESOURCE_GROUP and AKS_CLUSTER_NAME environment variables.
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.1.0' 'aks-connect'

SCRIPT_USAGE='Usage: aks-connect.sh'
handle_help "$@"
validate_arg_count 0 0 "$@"

RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-challenge2-rg}"
CLUSTER_NAME="${AKS_CLUSTER_NAME:-challenge-aks}"
validate_non_empty AZURE_RESOURCE_GROUP "$RESOURCE_GROUP"
validate_non_empty AKS_CLUSTER_NAME "$CLUSTER_NAME"

require_command az
require_command kubectl

log_info "Fetching credentials for AKS cluster $CLUSTER_NAME in $RESOURCE_GROUP"
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
kubectl cluster-info
kubectl get nodes -o wide
