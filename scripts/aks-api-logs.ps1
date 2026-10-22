# Script: aks-api-logs.ps1
# Version: 1.1.0
# Summary: Displays or follows logs from a Kubernetes deployment.
# Usage: aks-api-logs.ps1 [deployment]
# Inputs: Optional deployment; K8S_NAMESPACE, FOLLOW, SINCE, and TAIL.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-api-logs' -Version '1.1.0' -Usage 'Usage: aks-api-logs.ps1 [deployment]' -MinimumArguments 0 -MaximumArguments 1 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $deployment = if ($ScriptArgs.Count -gt 0 -and $ScriptArgs[0]) { $ScriptArgs[0] } else { 'dolly-api' }
  $follow = Get-ScriptEnvironmentValue 'FOLLOW' 'true'
  $since = Get-ScriptEnvironmentValue 'SINCE' '30m'
  $tail = Get-ScriptEnvironmentValue 'TAIL' '200'
  Assert-Boolean FOLLOW $follow
  Assert-Duration SINCE $since
  Assert-Integer TAIL $tail
  Require-NativeCommand kubectl
  $logArgs = @('logs', "deployment/$deployment", '--namespace', $namespace, '--all-containers=true', "--since=$since", "--tail=$tail")
  if ($follow -eq 'true') {
    Write-ScriptLog INFO "Following recent logs for deployment $deployment in $namespace"
    Invoke-NativeCommand kubectl ($logArgs + @('--follow'))
  }
  else {
    Write-ScriptLog INFO "Showing recent logs for deployment $deployment in $namespace"
    Invoke-NativeCommand kubectl $logArgs
  }
}
