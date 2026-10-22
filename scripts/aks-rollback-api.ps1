# Script: aks-rollback-api.ps1
# Version: 1.1.0
# Summary: Rolls back the Dolly API deployment to its previous or selected revision.
# Usage: aks-rollback-api.ps1 [revision]
# Inputs: Optional positive revision; K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-rollback-api' -Version '1.1.0' -Usage 'Usage: aks-rollback-api.ps1 [revision]' -MinimumArguments 0 -MaximumArguments 1 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand kubectl
  $revision = if ($ScriptArgs.Count -gt 0) { $ScriptArgs[0] } else { '' }
  $undoArgs = @('rollout', 'undo', '--namespace', $namespace, 'deployment/dolly-api')
  if ($revision) {
    Assert-Integer REVISION $revision
    $undoArgs += "--to-revision=$revision"
  }
  $revisionLabel = if ($revision) { " to revision $revision" } else { '' }
  Write-ScriptLog WARN "Rolling back Dolly API in namespace $namespace$revisionLabel"
  Invoke-NativeCommand kubectl $undoArgs
  Invoke-NativeCommand kubectl @('rollout', 'status', '--namespace', $namespace, 'deployment/dolly-api', "--timeout=$timeout")
}
