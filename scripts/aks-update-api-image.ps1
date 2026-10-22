# Script: aks-update-api-image.ps1
# Version: 1.1.0
# Summary: Updates the Dolly API container image and waits for rollout.
# Usage: aks-update-api-image.ps1 <registry/image:tag>
# Inputs: Required image; optional K8S_NAMESPACE, DEPLOYMENT, CONTAINER, and ROLLOUT_TIMEOUT.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-update-api-image' -Version '1.1.0' -Usage 'Usage: aks-update-api-image.ps1 <registry/image:tag>' -MinimumArguments 1 -MaximumArguments 1 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $image = $ScriptArgs[0]
  $deployment = Get-ScriptEnvironmentValue 'DEPLOYMENT' 'dolly-api'
  $container = Get-ScriptEnvironmentValue 'CONTAINER' 'dolly-api'
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-NonEmpty IMAGE $image
  Assert-NonEmpty DEPLOYMENT $deployment
  Assert-NonEmpty CONTAINER $container
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Updating container $container in deployment $deployment to $image"
  Invoke-NativeCommand kubectl @('set', 'image', '--namespace', $namespace, "deployment/$deployment", "$container=$image")
  Invoke-NativeCommand kubectl @('rollout', 'status', '--namespace', $namespace, "deployment/$deployment", "--timeout=$timeout")
}
