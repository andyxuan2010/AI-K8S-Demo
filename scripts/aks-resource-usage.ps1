# Script: aks-resource-usage.ps1
# Version: 1.1.0
# Summary: Displays node, pod, and horizontal pod autoscaler resource information.
# Usage: aks-resource-usage.ps1
# Inputs: Optional K8S_NAMESPACE; metrics-server is required for kubectl top.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-resource-usage' -Version '1.1.0' -Usage 'Usage: aks-resource-usage.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  Require-NativeCommand kubectl
  Write-ScriptLog INFO 'Reading node and pod resource usage; metrics-server is required'
  Invoke-NativeCommand kubectl @('top', 'nodes')
  Invoke-NativeCommand kubectl @('top', 'pods', '--namespace', $namespace, '--containers')
  Invoke-NativeCommand kubectl @('get', 'hpa', '--namespace', $namespace, '-o', 'wide', '--ignore-not-found')
}
