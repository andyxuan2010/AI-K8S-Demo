# Script: aks-ingress-logs.ps1
# Version: 1.1.0
# Summary: Displays or follows logs from the ingress controller deployment.
# Usage: aks-ingress-logs.ps1
# Inputs: INGRESS_NAMESPACE, INGRESS_DEPLOYMENT, FOLLOW, SINCE, and TAIL environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-ingress-logs' -Version '1.1.0' -Usage 'Usage: aks-ingress-logs.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'INGRESS_NAMESPACE' 'ingress-nginx'
  $deployment = Get-ScriptEnvironmentValue 'INGRESS_DEPLOYMENT' 'ingress-nginx-controller'
  $follow = Get-ScriptEnvironmentValue 'FOLLOW' 'true'
  $since = Get-ScriptEnvironmentValue 'SINCE' '30m'
  $tail = Get-ScriptEnvironmentValue 'TAIL' '200'
  Assert-Boolean FOLLOW $follow
  Assert-Duration SINCE $since
  Assert-Integer TAIL $tail
  Require-NativeCommand kubectl
  $logArgs = @('logs', "deployment/$deployment", '--namespace', $namespace, '--all-containers=true', "--since=$since", "--tail=$tail")
  if ($follow -eq 'true') {
    Write-ScriptLog INFO "Following ingress controller logs in namespace $namespace"
    Invoke-NativeCommand kubectl ($logArgs + @('--follow'))
  }
  else {
    Write-ScriptLog INFO "Showing recent ingress controller logs in namespace $namespace"
    Invoke-NativeCommand kubectl $logArgs
  }
}
