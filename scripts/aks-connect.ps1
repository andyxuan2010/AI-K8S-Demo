# Script: aks-connect.ps1
# Version: 1.1.0
# Summary: Fetches AKS credentials and displays cluster status.
# Usage: aks-connect.ps1
# Inputs: AZURE_RESOURCE_GROUP and AKS_CLUSTER_NAME environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-connect' -Version '1.1.0' -Usage 'Usage: aks-connect.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $resourceGroup = Get-ScriptEnvironmentValue 'AZURE_RESOURCE_GROUP' 'challenge2-rg'
  $clusterName = Get-ScriptEnvironmentValue 'AKS_CLUSTER_NAME' 'challenge-aks'
  Assert-NonEmpty 'AZURE_RESOURCE_GROUP' $resourceGroup
  Assert-NonEmpty 'AKS_CLUSTER_NAME' $clusterName
  Require-NativeCommand 'az'
  Require-NativeCommand 'kubectl'
  Write-ScriptLog INFO "Fetching credentials for AKS cluster $clusterName in $resourceGroup"
  Invoke-NativeCommand az @('aks', 'get-credentials', '--resource-group', $resourceGroup, '--name', $clusterName, '--overwrite-existing')
  Invoke-NativeCommand kubectl @('cluster-info')
  Invoke-NativeCommand kubectl @('get', 'nodes', '-o', 'wide')
}
