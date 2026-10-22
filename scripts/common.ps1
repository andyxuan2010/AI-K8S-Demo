# Script: common.ps1
# Version: 1.1.0
# Summary: Shared PowerShell logging, input validation, and native-command handling.
# Usage: Dot-source this file, then call Invoke-ManagedScript.

Set-StrictMode -Version 2.0

function Get-ScriptEnvironmentValue {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Default
  )
  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) { return $Default }
  return $value
}

function Write-ScriptLog {
  param(
    [Parameter(Mandatory = $true)][ValidateSet('INFO', 'WARN', 'ERROR', 'OUTPUT')][string]$Level,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Message
  )
  $timestamp = [DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ssZ')
  $line = "[$timestamp] [$Level] $Message"
  if ($global:ScriptLogFile) {
    Add-Content -LiteralPath $global:ScriptLogFile -Value $line -Encoding UTF8
  }
  if ($Level -eq 'ERROR' -or $Level -eq 'WARN') { [Console]::Error.WriteLine($line) }
  else { [Console]::Out.WriteLine($line) }
}

function Resolve-NativeCommand {
  param([Parameter(Mandatory = $true)][string]$Name)
  $application = Get-Command -Name $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
  if (-not $application) {
    throw [System.InvalidOperationException]::new("Required command not found: $Name")
  }
  return $application.Source
}

function Require-NativeCommand {
  param([Parameter(Mandatory = $true)][string]$Name)
  [void](Resolve-NativeCommand -Name $Name)
}

function Invoke-NativeCommand {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter()][AllowEmptyCollection()][string[]]$Arguments = @(),
    [switch]$PassThru,
    [switch]$CaptureOnly
  )
  $executable = Resolve-NativeCommand -Name $Name
  & $executable @Arguments 2>&1 | ForEach-Object {
    $line = [string]$_
    if (-not $CaptureOnly) { Write-ScriptLog -Level OUTPUT -Message $line }
    if ($PassThru) { $_ }
  }
  $exitCode = $LASTEXITCODE
  if ($null -eq $exitCode) { $exitCode = 0 }
  if ($exitCode -ne 0) {
    throw [System.Exception]::new("Command '$Name' failed with exit code $exitCode")
  }
}

function Assert-ArgumentCount {
  param(
    [Parameter(Mandatory = $true)][int]$Minimum,
    [Parameter(Mandatory = $true)][int]$Maximum,
    [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Arguments,
    [Parameter(Mandatory = $true)][string]$Usage
  )
  if ($Arguments.Count -lt $Minimum -or $Arguments.Count -gt $Maximum) {
    throw [System.ArgumentException]::new("Invalid number of arguments. Usage: $Usage")
  }
}

function Assert-NonEmpty {
  param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) {
    throw [System.ArgumentException]::new("$Name must not be empty.")
  }
}

function Assert-Integer {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value,
    [switch]$AllowZero,
    [int]$Maximum = 0
  )
  $pattern = if ($AllowZero) { '^(0|[1-9][0-9]*)$' } else { '^[1-9][0-9]*$' }
  if ($Value -notmatch $pattern) {
    $kind = if ($AllowZero) { 'non-negative' } else { 'positive' }
    throw [System.ArgumentException]::new("$Name must be a $kind integer.")
  }
  if ($Maximum -gt 0) {
    $numericValue = 0L
    if (-not [long]::TryParse($Value, [ref]$numericValue)) {
      throw [System.ArgumentException]::new("$Name is outside the supported integer range.")
    }
    if ($numericValue -gt $Maximum) {
      throw [System.ArgumentException]::new("$Name must not exceed $Maximum.")
    }
  }
}

function Assert-Boolean {
  param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][string]$Value)
  if ($Value -cnotin @('true', 'false')) {
    throw [System.ArgumentException]::new("$Name must be 'true' or 'false'.")
  }
}

function Assert-Duration {
  param([Parameter(Mandatory = $true)][string]$Name, [Parameter(Mandatory = $true)][string]$Value)
  if ($Value -notmatch '^([0-9]+(\.[0-9]+)?(ns|us|ms|s|m|h))+$') {
    throw [System.ArgumentException]::new("$Name must be a duration such as 30s, 5m, or 1m30s.")
  }
}

function Invoke-ManagedScript {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Version,
    [Parameter(Mandatory = $true)][string]$Usage,
    [Parameter(Mandatory = $true)][int]$MinimumArguments,
    [Parameter(Mandatory = $true)][int]$MaximumArguments,
    [Parameter()][AllowEmptyCollection()][string[]]$Arguments = @(),
    [Parameter()][string]$LogFile,
    [Parameter(Mandatory = $true)][scriptblock]$Action
  )

  $stateRoot = Get-ScriptEnvironmentValue -Name 'XDG_STATE_HOME' -Default (Join-Path $HOME '.local/state')
  $logDirectory = Get-ScriptEnvironmentValue -Name 'SCRIPT_LOG_DIR' -Default (Join-Path $stateRoot 'ai-k8s-demo/logs')
  if ($LogFile) {
    $global:ScriptLogFile = $LogFile
    $logDirectory = Split-Path -Parent $LogFile
  }
  else {
    $global:ScriptLogFile = Join-Path $logDirectory "$Name.log"
  }
  try {
    [void](New-Item -ItemType Directory -Path $logDirectory -Force)
    if (-not (Test-Path -LiteralPath $global:ScriptLogFile)) {
      [void](New-Item -ItemType File -Path $global:ScriptLogFile -Force)
    }
    Write-ScriptLog -Level INFO -Message "Starting $Name v$Version (pid $PID)"
    Write-ScriptLog -Level INFO -Message "Log file: $global:ScriptLogFile"

    if ($Arguments.Count -eq 1 -and $Arguments[0] -in @('-h', '--help')) {
      Write-ScriptLog -Level INFO -Message $Usage
      return
    }
    if ($Arguments.Count -eq 0 -and $MinimumArguments -eq 0) {
      Write-ScriptLog -Level INFO -Message $Usage
    }
    Assert-ArgumentCount -Minimum $MinimumArguments -Maximum $MaximumArguments -Arguments $Arguments -Usage $Usage
    & $Action $Arguments
    Write-ScriptLog -Level INFO -Message "Completed $Name v$Version successfully"
  }
  catch {
    $exitCode = if ($_.Exception -is [System.ArgumentException]) { 2 } else { 1 }
    Write-ScriptLog -Level ERROR -Message "$Name v$Version failed: $($_.Exception.Message)"
    Write-ScriptLog -Level ERROR -Message "Exiting with status $exitCode"
    $global:LASTEXITCODE = $exitCode
    exit $exitCode
  }
}
