# Script: aks-cleanup-demo.ps1
# Version: 1.1.0
# Summary: Deletes Dolly API and demo NGINX resources from the selected namespace.
# Usage: aks-cleanup-demo.ps1
# Inputs: Optional K8S_NAMESPACE environment variable.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-cleanup-demo' -Version '1.1.0' -Usage 'Usage: aks-cleanup-demo.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $repoRoot = Split-Path -Parent $PSScriptRoot
  $k8sDir = Join-Path $repoRoot 'k8s'
  $namespace = Get-ScriptEnvironmentValue 'K8S_NAMESPACE' 'default'
  Require-NativeCommand kubectl
  Write-ScriptLog WARN "Deleting Dolly API and demo NGINX resources from namespace $namespace"
  $apiArgs = @('delete', '--namespace', $namespace)
  foreach ($file in @('ingress.yaml', 'service.yaml', 'deployment.yaml')) {
    $apiArgs += @('-f', (Join-Path $k8sDir $file))
  }
  $apiArgs += '--ignore-not-found'
  Invoke-NativeCommand kubectl $apiArgs
  $nginxArgs = @('delete', '--namespace', $namespace)
  foreach ($file in @('nginx-ingress.yaml', 'nginx-service.yaml', 'nginx-deployment.yaml')) {
    $nginxArgs += @('-f', (Join-Path $k8sDir $file))
  }
  $nginxArgs += '--ignore-not-found'
  Invoke-NativeCommand kubectl $nginxArgs
}
