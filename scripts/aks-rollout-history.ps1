# Script: aks-rollout-history.ps1
# Version: 1.1.0
# Summary: Displays deployment rollout history, optionally for one revision.
# Usage: aks-rollout-history.ps1 [deployment [revision]]
# Inputs: Optional deployment and positive revision; K8S_NAMESPACE environment variable.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-rollout-history' -Version '1.1.0' -Usage 'Usage: aks-rollout-history.ps1 [deployment [revision]]' -MinimumArguments 0 -MaximumArguments 2 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $deployment = if ($ScriptArgs.Count -gt 0 -and $ScriptArgs[0]) { $ScriptArgs[0] } else { 'dolly-api' }
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Reading rollout history for deployment $deployment in namespace $namespace"
  $commandArgs = @('rollout', 'history', '--namespace', $namespace, "deployment/$deployment")
  if ($ScriptArgs.Count -gt 1 -and $ScriptArgs[1]) {
    Assert-Integer REVISION $ScriptArgs[1]
    $commandArgs += "--revision=$($ScriptArgs[1])"
  }
  Invoke-NativeCommand kubectl $commandArgs
}
