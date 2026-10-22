# Script: userdata-linux.ps1
# Version: 1.1.0
# Summary: Bootstraps an Ubuntu or Red Hat family VM with container and Kubernetes tools.
# Usage: userdata-linux.ps1
# Inputs: Optional BOOTSTRAP_LOG_FILE, KUBECTL_VERSION, and HELM_VERSION environment variables.
. "$PSScriptRoot/common.ps1"
$bootstrapLog = Get-ScriptEnvironmentValue 'BOOTSTRAP_LOG_FILE' '/var/log/aks-vm-bootstrap.log'
Invoke-ManagedScript -Name 'userdata-linux' -Version '1.1.0' -Usage 'Usage: userdata-linux.ps1' -MinimumArguments 0 -MaximumArguments 0 -Arguments $args -LogFile $bootstrapLog -Action {
  param([string[]]$ScriptArgs)

  if (-not (Test-Path -LiteralPath '/etc/os-release')) {
    throw [System.ArgumentException]::new('This bootstrap requires Ubuntu or a Red Hat family Linux distribution.')
  }
  $osValues = @{}
  foreach ($line in [System.IO.File]::ReadAllLines('/etc/os-release')) {
    if ($line -match '^([A-Z_]+)=(.*)$') {
      $osValues[$Matches[1]] = $Matches[2].Trim('"').ToLowerInvariant()
    }
  }
  $identity = "$($osValues['ID']) $($osValues['ID_LIKE'])"
  if ($identity -match '(^|\s)ubuntu(\s|$)') { $osFamily = 'ubuntu' }
  elseif ($identity -match '(^|\s)(rhel|redhat|centos|rocky|almalinux|ol|fedora)(\s|$)') { $osFamily = 'redhat' }
  else { throw [System.ArgumentException]::new("Unsupported Linux distribution: $($osValues['PRETTY_NAME'])") }

  $uid = Invoke-NativeCommand id @('-u') -PassThru | Select-Object -Last 1
  if ([string]$uid -ne '0') { throw [System.ArgumentException]::new('Run this bootstrap script as root.') }
  try { Invoke-NativeCommand id @('azuser') | Out-Null }
  catch { throw [System.ArgumentException]::new("Expected VM administrator account 'azuser' was not found.") }

  $kubectlVersion = Get-ScriptEnvironmentValue 'KUBECTL_VERSION' 'v1.26.3'
  $helmVersion = Get-ScriptEnvironmentValue 'HELM_VERSION' 'v4.3.1'
  if ($kubectlVersion -notmatch '^v?[0-9]+\.[0-9]+\.[0-9]+$') {
    throw [System.ArgumentException]::new('KUBECTL_VERSION must use a semantic version such as v1.26.3.')
  }
  if ($helmVersion -notmatch '^v?[0-9]+\.[0-9]+\.[0-9]+$') {
    throw [System.ArgumentException]::new('HELM_VERSION must use a semantic version such as v4.3.1.')
  }
  if ($kubectlVersion -notmatch '^v') { $kubectlVersion = "v$kubectlVersion" }
  if ($helmVersion -notmatch '^v') { $helmVersion = "v$helmVersion" }

  $architecture = (Invoke-NativeCommand uname @('-m') -PassThru | Select-Object -Last 1).ToString().Trim()
  switch -Regex ($architecture) {
    '^(x86_64|amd64)$' { $k8sArch = 'amd64'; $awsArch = 'x86_64'; break }
    '^(aarch64|arm64)$' { $k8sArch = 'arm64'; $awsArch = 'aarch64'; break }
    default { throw [System.ArgumentException]::new("Unsupported CPU architecture: $architecture (supported: x86_64, aarch64)") }
  }
  $sshService = if ($osFamily -eq 'ubuntu') { 'ssh' } else { 'sshd' }

  function Add-LineOnce {
    param([string]$Path, [string]$Line)
    if (-not (Test-Path -LiteralPath $Path)) { [System.IO.File]::WriteAllText($Path, '') }
    $lines = [System.IO.File]::ReadAllLines($Path)
    if ($lines -notcontains $Line) { [System.IO.File]::AppendAllText($Path, "$Line`n") }
  }

  Write-ScriptLog INFO "Validated Linux distribution family: $osFamily"
  if ($osFamily -eq 'ubuntu') {
    Write-ScriptLog INFO 'Updating Ubuntu packages and installing VM tools'
    $env:DEBIAN_FRONTEND = 'noninteractive'
    Invoke-NativeCommand apt-get @('update', '-y')
    Invoke-NativeCommand apt-get @('upgrade', '-y')
    Invoke-NativeCommand apt-get @('install', '-y', 'ca-certificates', 'curl', 'gnupg', 'unzip', 'jq', 'golang-go', 'nfs-common', 'binutils', 'bash-completion', 'net-tools', 'nmap')
    Invoke-NativeCommand install @('-m', '0755', '-d', '/etc/apt/keyrings')
    Invoke-NativeCommand curl @('-fsSL', 'https://download.docker.com/linux/ubuntu/gpg', '-o', '/etc/apt/keyrings/docker.asc')
    Invoke-NativeCommand chmod @('a+r', '/etc/apt/keyrings/docker.asc')
    $release = @{}
    foreach ($line in [System.IO.File]::ReadAllLines('/etc/os-release')) {
      if ($line -match '^([A-Z_]+)=(.*)$') { $release[$Matches[1]] = $Matches[2].Trim('"') }
    }
    $codename = if ($release['UBUNTU_CODENAME']) { $release['UBUNTU_CODENAME'] } else { $release['VERSION_CODENAME'] }
    $architectureName = (Invoke-NativeCommand dpkg @('--print-architecture') -PassThru | Select-Object -Last 1).ToString().Trim()
    $dockerSource = @"
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $codename
Components: stable
Architectures: $architectureName
Signed-By: /etc/apt/keyrings/docker.asc
"@
    [System.IO.File]::WriteAllText('/etc/apt/sources.list.d/docker.sources', $dockerSource)
    Invoke-NativeCommand apt-get @('update', '-y')
    Invoke-NativeCommand apt-get @('install', '-y', 'docker-ce', 'docker-ce-cli', 'containerd.io', 'docker-buildx-plugin', 'docker-compose-plugin')
  }
  else {
    Write-ScriptLog INFO 'Updating Red Hat family packages and installing VM tools'
    Invoke-NativeCommand dnf @('upgrade', '--refresh', '-y')
    Invoke-NativeCommand dnf @('install', '-y', 'ca-certificates', 'curl', 'gnupg2', 'unzip', 'jq', 'golang', 'nfs-utils', 'binutils', 'bash-completion', 'net-tools', 'nmap', 'dnf-plugins-core')
    Invoke-NativeCommand dnf @('config-manager', '--add-repo', 'https://download.docker.com/linux/rhel/docker-ce.repo')
    Invoke-NativeCommand dnf @('install', '-y', 'docker-ce', 'docker-ce-cli', 'containerd.io', 'docker-buildx-plugin', 'docker-compose-plugin')
  }

  if (-not (Get-Command aws -CommandType Application -ErrorAction SilentlyContinue)) {
    $workDir = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
    [void](New-Item -ItemType Directory -Path $workDir -Force)
    try {
      $zipPath = Join-Path $workDir 'awscliv2.zip'
      Write-ScriptLog INFO "Installing AWS CLI for $awsArch"
      Invoke-NativeCommand curl @('-fsSL', "https://awscli.amazonaws.com/awscli-exe-linux-$awsArch.zip", '-o', $zipPath)
      Invoke-NativeCommand unzip @('-q', $zipPath, '-d', $workDir)
      Invoke-NativeCommand (Join-Path $workDir 'aws/install') @()
    }
    finally { Remove-Item -LiteralPath $workDir -Recurse -Force -ErrorAction SilentlyContinue }
  }

  Write-ScriptLog INFO "Installing kubectl $kubectlVersion for linux/$k8sArch"
  Invoke-NativeCommand curl @('-fsSL', "https://dl.k8s.io/release/$kubectlVersion/bin/linux/$k8sArch/kubectl", '-o', '/usr/local/bin/kubectl')
  Invoke-NativeCommand chmod @('0755', '/usr/local/bin/kubectl')
  $helmWork = Join-Path ([System.IO.Path]::GetTempPath()) ([Guid]::NewGuid().ToString('N'))
  [void](New-Item -ItemType Directory -Path $helmWork -Force)
  try {
    $helmArchive = Join-Path $helmWork 'helm.tar.gz'
    Write-ScriptLog INFO "Installing Helm $helmVersion for linux/$k8sArch"
    Invoke-NativeCommand curl @('-fsSL', "https://get.helm.sh/helm-$helmVersion-linux-$k8sArch.tar.gz", '-o', $helmArchive)
    Invoke-NativeCommand tar @('-xzf', $helmArchive, '-C', $helmWork)
    Invoke-NativeCommand install @('-m', '0755', (Join-Path $helmWork "linux-$k8sArch/helm"), '/usr/local/bin/helm')
  }
  finally { Remove-Item -LiteralPath $helmWork -Recurse -Force -ErrorAction SilentlyContinue }

  Invoke-NativeCommand ln @('-sf', '/usr/share/zoneinfo/America/New_York', '/etc/localtime')
  Add-LineOnce '/etc/ssh/sshd_config' 'ClientAliveInterval 1200'
  Add-LineOnce '/etc/ssh/sshd_config' 'ClientAliveCountMax 3'
  Invoke-NativeCommand systemctl @('restart', $sshService)
  Invoke-NativeCommand install @('-d', '-m', '0700', '/root/.ssh', '/home/azuser/.ssh')
  foreach ($authorized in @('/root/.ssh/authorized_keys', '/home/azuser/.ssh/authorized_keys')) {
    if (-not (Test-Path -LiteralPath $authorized)) { [System.IO.File]::WriteAllText($authorized, '') }
    Invoke-NativeCommand chmod @('0600', $authorized)
  }

  $emachineKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIqfriZJbopqGHXo1gVfxo7LNF7rx+Yq1qSFpLeojDS4DWr/a8v2dpevDf95Xku/BGLZ16eRQFlW4/YFfhpPIy1sYVlaJQVOiALN8sk1R5OuGjLXy2e22SRVgH0LQehHCLwmszjuLhbmDO8qjNnzm0JIYHmv4+VkZ56LI8rTiPozHmKGxgKfhKhV1vh9NzdCnj7Nh/iQWAU82X5UzYU6J6t7Ape1bp4C74yPH3NOcVcV51qKZXiamfM2PfPnU11I+Wd7Ho8l1yvpUUZe0FdSBZtp7oWya+oPy5AXJlfuMCq5WjVUO9LCvpZMsJWQDhocMFuDRiNw4+0G/XnathEiRP root@emachine'
  $vmKey = 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjoftGI4Wgwc6YHGgbbUfAkMm2k4JQIkMXmlHrs24bnSa+CxNeC4eL7cFWZHgLxn6pBfqRCijsCbLpzUhlIJKMMxv2WB0TtHpezD9oUX1/9K7rC3RB4EcKmZ3vDWSsR4UBn9aVCZkQBnr+hfk39lj+Hk2qAMGloVFD0bM10j1Hhv5uMaT8lcClWK/TCcgKH8NQF3hZDqX8YADCYczvZ7B3hA+xpAZwOOZKChOv5Y2ABduD8KPcV6Uc1VLO6+xMlkDZc0MB6HkYlGZSbeMkstgPo+275SKHWVJ7B2nWMvOAyOtjU5OqHwYoNrsCX1TP380DUhQqqAqjzqDP8C0z76Gj root@vm'
  Add-LineOnce '/root/.ssh/authorized_keys' $emachineKey
  Add-LineOnce '/root/.ssh/authorized_keys' $vmKey
  Add-LineOnce '/home/azuser/.ssh/authorized_keys' $emachineKey
  Add-LineOnce '/home/azuser/.ssh/authorized_keys' $vmKey
  Invoke-NativeCommand chown @('-R', 'azuser:azuser', '/home/azuser/.ssh')
  Invoke-NativeCommand systemctl @('enable', '--now', 'docker')
  Invoke-NativeCommand usermod @('-aG', 'docker', 'azuser')

  foreach ($accountHome in @('/root', '/home/azuser')) {
    $bashrc = Join-Path $accountHome '.bashrc'
    Add-LineOnce $bashrc 'alias k=kubectl'
    Add-LineOnce $bashrc 'alias c=clear'
    Add-LineOnce $bashrc 'source <(kubectl completion bash)'
    Add-LineOnce $bashrc "export PROMPT_COMMAND='history -a'"
  }
  Invoke-NativeCommand chown @('azuser:azuser', '/home/azuser/.bashrc')
  Write-ScriptLog INFO 'Installing Kubernetes ingress controller and dashboard'
  Invoke-NativeCommand su @('-', 'azuser', '-c', 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml')
  Invoke-NativeCommand su @('-', 'azuser', '-c', 'kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml')
  Write-ScriptLog INFO 'Deploying the demo NGINX service'
  Invoke-NativeCommand su @('-', 'azuser', '-c', 'cd k8s; kubectl apply -f nginx-deployment.yaml -f nginx-service.yaml -f nginx-ingress.yaml')
  Add-LineOnce '/etc/resolv.conf' 'search argentiacapital.com'
}
