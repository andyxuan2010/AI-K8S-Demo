# Script: aks-install-ingress.ps1
# Version: 1.1.0
# Summary: Installs ingress-nginx and waits for its controller rollout.
# Usage: aks-install-ingress.ps1
# Inputs: INGRESS_NGINX_MANIFEST_URL and ROLLOUT_TIMEOUT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-install-ingress' -Version '1.1.0' -Usage 'Usage: aks-install-ingress.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $manifestUrl = Get-ScriptEnvironmentValue 'INGRESS_NGINX_MANIFEST_URL' 'https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml'
  $timeout = Get-ScriptEnvironmentValue 'ROLLOUT_TIMEOUT' '300s'
  Assert-NonEmpty INGRESS_NGINX_MANIFEST_URL $manifestUrl
  Assert-Duration ROLLOUT_TIMEOUT $timeout
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Applying ingress-nginx manifest: $manifestUrl"
  Invoke-NativeCommand kubectl @('apply', '-f', $manifestUrl)
  Invoke-NativeCommand kubectl @('rollout', 'status', '--namespace', 'ingress-nginx', 'deployment/ingress-nginx-controller', "--timeout=$timeout")
}
