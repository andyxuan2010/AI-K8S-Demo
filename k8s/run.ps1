# Script: run.ps1
# Version: 1.1.0
# Summary: Builds and pushes the Dolly API image, applies manifests, and waits for rollout.
# Usage: run.ps1
# Inputs: Optional IMAGE, PUBLISHED_IMAGE, and ROLLOUT_TIMEOUT environment variables.
. "$(Join-Path (Split-Path -Parent $PSScriptRoot) 'scripts/common.ps1')"
Invoke-ManagedScript -Name 'k8s-run' -Version '1.1.0' -Usage 'Usage: run.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $image = Get-ScriptEnvironmentValue 'IMAGE' 'dolly-api:v1.1'
  $publishedImage = Get-ScriptEnvironmentValue 'PUBLISHED_IMAGE' 'andyxuan2010/dolly-api:v1.1'
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-NonEmpty IMAGE $image
  Assert-NonEmpty PUBLISHED_IMAGE $publishedImage
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand docker
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Building local image $image"
  Invoke-NativeCommand docker @('build', '--tag', $image, $PSScriptRoot)
  Invoke-NativeCommand docker @('images', $image)
  if ($image -ne $publishedImage) {
    Write-ScriptLog INFO "Tagging $image as $publishedImage"
    Invoke-NativeCommand docker @('tag', $image, $publishedImage)
  }
  Write-ScriptLog INFO "Pushing image $publishedImage"
  Invoke-NativeCommand docker @('push', $publishedImage)
  Write-ScriptLog INFO 'Applying Dolly API deployment, service, and ingress manifests'
  Invoke-NativeCommand kubectl @('apply', '-f', (Join-Path $PSScriptRoot 'deployment.yaml'), '-f', (Join-Path $PSScriptRoot 'service.yaml'), '-f', (Join-Path $PSScriptRoot 'ingress.yaml'))
  Invoke-NativeCommand kubectl @('rollout', 'status', 'deployment/dolly-api', "--timeout=$timeout")
}
