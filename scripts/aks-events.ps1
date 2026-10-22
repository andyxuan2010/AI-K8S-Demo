# Script: aks-events.ps1
# Version: 1.1.0
# Summary: Lists the most recent events in a Kubernetes namespace.
# Usage: aks-events.ps1
# Inputs: Optional K8S_NAMESPACE and EVENT_LIMIT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-events' -Version '1.1.0' -Usage 'Usage: aks-events.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $limit = Get-ScriptEnvironmentValue 'EVENT_LIMIT' '50'
  Assert-Integer EVENT_LIMIT $limit
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Showing the latest $limit events in namespace $namespace"
  $lines = Invoke-NativeCommand kubectl @('get', 'events', '--namespace', $namespace, '--sort-by=.metadata.creationTimestamp') -PassThru -CaptureOnly
  $lines | Select-Object -Last ([int]$limit) | ForEach-Object { Write-ScriptLog OUTPUT ([string]$_) }
}
