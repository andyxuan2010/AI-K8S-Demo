#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/common.sh"
script_init '1.0.0' 'aks-connect'

RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-challenge2-rg}"
CLUSTER_NAME="${AKS_CLUSTER_NAME:-challenge-aks}"

require_command az
require_command kubectl

log_info "Fetching credentials for AKS cluster $CLUSTER_NAME in $RESOURCE_GROUP"
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --overwrite-existing
kubectl cluster-info
kubectl get nodes -o wide
