# Script: aks-preflight-check.ps1
# Version: 1.1.0
# Summary: Checks cluster access, namespace availability, and server-side manifest validation.
# Usage: aks-preflight-check.ps1
# Inputs: Optional K8S_NAMESPACE environment variable.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-preflight-check' -Version '1.1.0' -Usage 'Usage: aks-preflight-check.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $repoRoot = Split-Path -Parent $PSScriptRoot
  $k8sDir = Join-Path $repoRoot 'k8s'
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Checking cluster connection and namespace $namespace"
  Invoke-NativeCommand kubectl @('config', 'current-context')
  Invoke-NativeCommand kubectl @('cluster-info')
  Invoke-NativeCommand kubectl @('get', 'namespace', $namespace) -PassThru -CaptureOnly | Out-Null
  foreach ($manifest in @('deployment.yaml', 'service.yaml', 'ingress.yaml')) {
    Write-ScriptLog INFO "Server-side validating $manifest"
    Invoke-NativeCommand kubectl @('apply', '--dry-run=server', '--namespace', $namespace, '-f', (Join-Path $k8sDir $manifest))
  }
  Write-ScriptLog INFO 'AKS preflight checks passed'
}
