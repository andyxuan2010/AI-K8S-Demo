# Script: aks-restart-api.ps1
# Version: 1.1.0
# Summary: Restarts the Dolly API deployment and waits for rollout.
# Usage: aks-restart-api.ps1
# Inputs: Optional K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-restart-api' -Version '1.1.0' -Usage 'Usage: aks-restart-api.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Restarting Dolly API in namespace $namespace"
  Invoke-NativeCommand kubectl @('rollout', 'restart', '--namespace', $namespace, 'deployment/dolly-api')
  Invoke-NativeCommand kubectl @('rollout', 'status', '--namespace', $namespace, 'deployment/dolly-api', "--timeout=$timeout")
}
