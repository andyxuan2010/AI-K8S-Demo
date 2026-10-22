# Script: aks-watch-pods.ps1
# Version: 1.1.0
# Summary: Watches pods in a Kubernetes namespace, optionally filtered by label selector.
# Usage: aks-watch-pods.ps1
# Inputs: Optional K8S_NAMESPACE and POD_SELECTOR environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-watch-pods' -Version '1.1.0' -Usage 'Usage: aks-watch-pods.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $selector = Get-ScriptEnvironmentValue 'POD_SELECTOR' ''
  Require-NativeCommand kubectl
  $selectorLabel = if ($selector) { " matching $selector" } else { '' }
  Write-ScriptLog INFO "Watching pods in namespace $namespace$selectorLabel; press Ctrl-C to stop"
  $commandArgs = @('get', 'pods', '--namespace', $namespace)
  if ($selector) { $commandArgs += @('--selector', $selector) }
  $commandArgs += @('--watch', '--output', 'wide')
  Invoke-NativeCommand kubectl $commandArgs
}
