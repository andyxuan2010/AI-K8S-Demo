# Script: aks-smoke-test.ps1
# Version: 1.1.0
# Summary: Sends an HTTP request to the configured API endpoint.
# Usage: aks-smoke-test.ps1
# Inputs: Optional API_URL and CURL_TIMEOUT environment variables.
. "$PSScriptRoot/common.ps1"
Invoke-ManagedScript -Name 'aks-smoke-test' -Version '1.1.0' -Usage 'Usage: aks-smoke-test.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -Action {
  param([string[]]$ScriptArgs)
  $url = Get-ScriptEnvironmentValue 'API_URL' 'https://basf.argentiacapital.com/'
  $timeout = Get-ScriptEnvironmentValue 'CURL_TIMEOUT' '20'
  Assert-NonEmpty API_URL $url
  Assert-Integer CURL_TIMEOUT $timeout
  $curl = if ($env:OS -eq 'Windows_NT') { 'curl.exe' } else { 'curl' }
  Require-NativeCommand $curl
  Write-ScriptLog INFO "Checking API endpoint: $url"
  Invoke-NativeCommand $curl @('--fail', '--silent', '--show-error', '--location', '--max-time', $timeout, $url)
  Write-ScriptLog INFO 'API endpoint responded successfully'
}
