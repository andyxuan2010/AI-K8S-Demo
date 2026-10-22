# Script: aks-port-forward-api.ps1
# Version: 1.1.0
# Summary: Forwards a local TCP port to the Dolly API Kubernetes service.
# Usage: aks-port-forward-api.ps1 [local-port]
# Inputs: K8S_NAMESPACE, SERVICE_NAME, and SERVICE_PORT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-port-forward-api' -Version '1.1.0' -Usage 'Usage: aks-port-forward-api.ps1 [local-port]' -MinimumArguments 0 -MaximumArguments 1 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  $localPort = if ($ScriptArgs.Count -gt 0 -and $ScriptArgs[0]) { $ScriptArgs[0] } else { '8000' }
  $service = Get-ScriptEnvironmentValue 'SERVICE_NAME' 'dolly-api-service'
  $servicePort = Get-ScriptEnvironmentValue 'SERVICE_PORT' '8000'
  Assert-Integer LOCAL_PORT $localPort -Maximum 65535
  Assert-Integer SERVICE_PORT $servicePort -Maximum 65535
  Require-NativeCommand kubectl
  Write-ScriptLog INFO "Forwarding localhost:$localPort to service/$service`:$servicePort in $namespace; press Ctrl-C to stop"
  Invoke-NativeCommand kubectl @('port-forward', '--namespace', $namespace, "service/$service", "$($localPort):$servicePort")
}
