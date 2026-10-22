# Script: aks-deploy-api.ps1
# Version: 1.1.0
# Summary: Applies Dolly API manifests and waits for deployment rollout.
# Usage: aks-deploy-api.ps1
# Inputs: Optional K8S_NAMESPACE and ROLLOUT_TIMEOUT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-deploy-api' -Version '1.1.0' -Usage 'Usage: aks-deploy-api.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $repoRoot = Split-Path -Parent $PSScriptRoot
  $k8sDir = Join-Path $repoRoot 'k8s'
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Applying Dolly API manifests to namespace $namespace"
  Invoke-NativeCommand kubectl @('apply', '--namespace', $namespace, '-f', (Join-Path $k8sDir 'deployment.yaml'), '-f', (Join-Path $k8sDir 'service.yaml'), '-f', (Join-Path $k8sDir 'ingress.yaml'))
  Invoke-NativeCommand kubectl @('rollout', 'status', '--namespace', $namespace, 'deployment/dolly-api', "--timeout=$timeout")
}
