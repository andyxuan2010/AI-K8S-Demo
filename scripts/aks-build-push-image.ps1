# Script: aks-build-push-image.ps1
# Version: 1.1.0
# Summary: Builds and pushes the Dolly API container image.
# Usage: aks-build-push-image.ps1
# Inputs: Optional IMAGE environment variable.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-build-push-image' -Version '1.1.0' -Usage 'Usage: aks-build-push-image.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $repoRoot = Split-Path -Parent $PSScriptRoot
  $image = Get-ScriptEnvironmentValue 'IMAGE' 'andyxuan2010/dolly-api:v1.0'
  Assert-NonEmpty 'IMAGE' $image
  Require-NativeCommand docker
  Write-ScriptLog INFO "Building and pushing image $image"
  Invoke-NativeCommand docker @('build', '--tag', $image, (Join-Path $repoRoot 'k8s'))
  Invoke-NativeCommand docker @('push', $image)
}
