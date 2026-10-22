# Script: aks-scale-api.ps1
# Version: 1.1.0
# Summary: Scales the Dolly API deployment to the requested replica count.
# Usage: aks-scale-api.ps1 <replica-count>
# Inputs: Required non-negative replica count; K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-scale-api' -Version '1.1.0' -Usage 'Usage: aks-scale-api.ps1 <replica-count>' -MinimumArguments 1 -MaximumArguments 1 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $replicas = $ScriptArgs[0]
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-Integer REPLICAS $replicas -AllowZero
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Scaling Dolly API to $replicas replicas in namespace $namespace"
  Invoke-NativeCommand kubectl @('scale', '--namespace', $namespace, 'deployment/dolly-api', "--replicas=$replicas")
  Invoke-NativeCommand kubectl @('rollout', 'status', '--namespace', $namespace, 'deployment/dolly-api', "--timeout=$timeout")
}
