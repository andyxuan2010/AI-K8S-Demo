# Script: aks-diagnostics.ps1
# Version: 1.1.0
# Summary: Collects cluster, namespace, event, and optional pod diagnostics.
# Usage: aks-diagnostics.ps1 [pod]
# Inputs: Optional pod; K8S_NAMESPACE and APP_LABEL environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-diagnostics' -Version '1.1.0' -Usage 'Usage: aks-diagnostics.ps1 [pod]' -MinimumArguments 0 -MaximumArguments 1 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $appLabel = Get-ScriptEnvironmentValue 'APP_LABEL' 'app=dolly-api'
  $pod = if ($ScriptArgs.Count -gt 0) { $ScriptArgs[0] } else { '' }
  Assert-NonEmpty APP_LABEL $appLabel
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Collecting AKS diagnostics for namespace $namespace"
  Invoke-NativeCommand kubectl @('get', 'nodes', '-o', 'wide')
  Invoke-NativeCommand kubectl @('get', 'deployments,replicasets,pods,services,ingresses', '--namespace', $namespace, '-o', 'wide')
  $events = Invoke-NativeCommand kubectl @('get', 'events', '--namespace', $namespace, '--sort-by=.metadata.creationTimestamp') -PassThru -CaptureOnly
  $events | Select-Object -Last 40 | ForEach-Object { Write-ScriptLog OUTPUT ([string]$_) }
  if ($pod) {
    Invoke-NativeCommand kubectl @('describe', 'pod', '--namespace', $namespace, $pod)
    Invoke-NativeCommand kubectl @('logs', '--namespace', $namespace, $pod, '--all-containers=true', '--tail=200')
  }
  else {
    try { Invoke-NativeCommand kubectl @('logs', '--namespace', $namespace, '--selector', $appLabel, '--all-containers=true', '--tail=200') }
    catch { Write-ScriptLog WARN "No matching pod logs were returned: $($_.Exception.Message)" }
  }
}
