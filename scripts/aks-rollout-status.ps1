# Script: aks-rollout-status.ps1
# Version: 1.1.0
# Summary: Waits for a deployment rollout and lists its pods.
# Usage: aks-rollout-status.ps1 [deployment]
# Inputs: Optional deployment; K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-rollout-status' -Version '1.1.0' -Usage 'Usage: aks-rollout-status.ps1 [deployment]' -MinimumArguments 0 -MaximumArguments 1 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $deployment = if ($ScriptArgs.Count -gt 0 -and $ScriptArgs[0]) { $ScriptArgs[0] } else { 'dolly-api' }
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-NonEmpty DEPLOYMENT $deployment
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Checking rollout status for deployment $deployment in namespace $namespace"
  Invoke-NativeCommand kubectl @('rollout', 'status', '--namespace', $namespace, "deployment/$deployment", "--timeout=$timeout")
  Invoke-NativeCommand kubectl @('get', 'deployment,pods', '--namespace', $namespace, '-o', 'wide')
}
