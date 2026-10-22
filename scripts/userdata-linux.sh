#!/usr/bin/env bash
# Script: userdata-linux.sh
# Version: 1.1.0
# Summary: Bootstraps an Ubuntu or Red Hat family VM with container and Kubernetes tools.
# Usage: userdata-linux.sh
# Inputs: Optional BOOTSTRAP_LOG_FILE, KUBECTL_VERSION, and HELM_VERSION environment variables.
set -Eeuo pipefail

SCRIPT_VERSION="1.1.0"
SCRIPT_NAME="userdata-linux"
SCRIPT_LOG_FILE="${BOOTSTRAP_LOG_FILE:-/var/log/aks-vm-bootstrap.log}"
SCRIPT_USAGE='Usage: userdata-linux.sh'
if [[ "$#" -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
  printf '%s\n' "$SCRIPT_USAGE"
  exit 0
fi
mkdir -p -- "$(dirname -- "$SCRIPT_LOG_FILE")"
touch "$SCRIPT_LOG_FILE"
chmod 600 "$SCRIPT_LOG_FILE"
exec > >(tee -a "$SCRIPT_LOG_FILE") 2>&1

log_info() {
  printf '[%s] [INFO] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
}

log_error() {
  printf '[%s] [ERROR] %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*" >&2
}

script_error_handler() {
  local status="$1"
  local line="$2"
  trap - ERR
  log_error "$SCRIPT_NAME v$SCRIPT_VERSION failed at line $line (exit $status)"
  exit "$status"
}

script_exit_handler() {
  local status="$1"
  if [[ "$status" -eq 0 ]]; then
    log_info "Completed $SCRIPT_NAME v$SCRIPT_VERSION successfully"
  else
    log_error "$SCRIPT_NAME v$SCRIPT_VERSION exited with status $status"
  fi
}

trap 'script_error_handler "$?" "$LINENO"' ERR
trap 'script_exit_handler "$?"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
log_info "Starting $SCRIPT_NAME v$SCRIPT_VERSION (pid $$)"
if [[ "$#" -ne 0 ]]; then
  log_error 'Invalid number of arguments.'
  log_error "$SCRIPT_USAGE"
  exit 2
fi
log_info "Log file: $SCRIPT_LOG_FILE"

detect_linux_family() {
  local os_release_file="${OS_RELEASE_FILE:-/etc/os-release}"
  [[ -r "$os_release_file" ]] || { log_error "Cannot read $os_release_file"; return 1; }
  # os-release is a shell-compatible file supplied by the operating system.
  # shellcheck disable=SC1090
  . "$os_release_file"
  local id="${ID:-}"
  local id_like="${ID_LIKE:-}"
  id="${id,,}"
  id_like="${id_like,,}"
  case " $id $id_like " in
    *" ubuntu "*) printf 'ubuntu\n' ;;
    *" rhel "*|*" redhat "*|*" centos "*|*" rocky "*|*" almalinux "*|*" ol "*|*" fedora "*) printf 'redhat\n' ;;
    *) log_error "Unsupported Linux distribution: ${PRETTY_NAME:-${ID:-unknown}}"; return 1 ;;
  esac
}

OS_FAMILY="$(detect_linux_family)"
if [[ "$(id -u)" -ne 0 ]]; then
  log_error "Run this bootstrap script as root."
  exit 1
fi
if ! id azuser >/dev/null 2>&1; then
  log_error "Expected VM administrator account 'azuser' was not found."
  exit 1
fi
log_info "Validated Linux distribution family: $OS_FAMILY"
if [[ "$OS_FAMILY" == "ubuntu" ]]; then
  SSH_SERVICE="ssh"
else
  SSH_SERVICE="sshd"
fi

KUBECTL_VERSION="${KUBECTL_VERSION:-v1.26.3}"
HELM_VERSION="${HELM_VERSION:-v4.3.1}"
if [[ ! "$KUBECTL_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log_error "KUBECTL_VERSION must use a semantic version such as v1.26.3."
  exit 2
fi
if [[ ! "$HELM_VERSION" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  log_error "HELM_VERSION must use a semantic version such as v4.3.1."
  exit 2
fi
[[ "$KUBECTL_VERSION" == v* ]] || KUBECTL_VERSION="v$KUBECTL_VERSION"
[[ "$HELM_VERSION" == v* ]] || HELM_VERSION="v$HELM_VERSION"

case "$(uname -m)" in
  x86_64|amd64) K8S_ARCH="amd64"; HELM_ARCH="amd64"; AWS_ARCH="x86_64" ;;
  aarch64|arm64) K8S_ARCH="arm64"; HELM_ARCH="arm64"; AWS_ARCH="aarch64" ;;
  *) log_error "Unsupported CPU architecture: $(uname -m) (supported: x86_64, aarch64)"; exit 1 ;;
esac

append_line_once() {
  local file="$1"
  local line="$2"
  touch "$file"
  if ! grep -Fqx -- "$line" "$file"; then
    printf '%s\n' "$line" >> "$file"
  fi
}

install_base_packages() {
  log_info "Updating packages and installing VM tools for $OS_FAMILY"
  if [[ "$OS_FAMILY" == "ubuntu" ]]; then
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    apt-get install -y ca-certificates curl gnupg unzip jq golang-go nfs-common binutils bash-completion net-tools nmap
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    chmod a+r /etc/apt/keyrings/docker.asc
    . /etc/os-release
    local ubuntu_codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"
    cat > /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $ubuntu_codename
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  else
    dnf upgrade --refresh -y
    dnf install -y ca-certificates curl gnupg2 unzip jq golang nfs-utils binutils bash-completion net-tools nmap dnf-plugins-core
    dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  fi
}

install_aws_cli() {
  if command -v aws >/dev/null 2>&1; then
    log_info "AWS CLI is already installed"
    return
  fi
  local work_dir
  work_dir="$(mktemp -d -t aks-aws-cli.XXXXXX)"
  log_info "Installing AWS CLI for $AWS_ARCH"
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip" -o "$work_dir/awscliv2.zip"
  unzip -q "$work_dir/awscliv2.zip" -d "$work_dir"
  "$work_dir/aws/install"
  rm -rf -- "$work_dir"
}

install_kubectl() {
  local version="$KUBECTL_VERSION"
  log_info "Installing kubectl $version for linux/$K8S_ARCH"
  curl -fsSL "https://dl.k8s.io/release/${version}/bin/linux/${K8S_ARCH}/kubectl" -o /usr/local/bin/kubectl
  chmod 0755 /usr/local/bin/kubectl
}

install_helm() {
  local version="$HELM_VERSION"
  local work_dir
  work_dir="$(mktemp -d -t aks-helm.XXXXXX)"
  log_info "Installing Helm $version for linux/$HELM_ARCH"
  curl -fsSL "https://get.helm.sh/helm-${version}-linux-${HELM_ARCH}.tar.gz" -o "$work_dir/helm.tar.gz"
  tar -xzf "$work_dir/helm.tar.gz" -C "$work_dir"
  install -m 0755 "$work_dir/linux-${HELM_ARCH}/helm" /usr/local/bin/helm
  rm -rf -- "$work_dir"
}

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

#add additional keepalive seconds to sshd
append_line_once /etc/ssh/sshd_config "ClientAliveInterval 1200"
append_line_once /etc/ssh/sshd_config "ClientAliveCountMax 3"
#sed -i -E 's/#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart "$SSH_SERVICE"

# install emachine key and vm key
install -d -m 0700 /root/.ssh /home/azuser/.ssh
touch /root/.ssh/authorized_keys /home/azuser/.ssh/authorized_keys
chmod 0600 /root/.ssh/authorized_keys /home/azuser/.ssh/authorized_keys
chown -R azuser:azuser /home/azuser/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIqfriZJbopqGHXo1gVfxo7LNF7rx+Yq1qSFpLeojDS4DWr/a8v2dpevDf95Xku/BGLZ16eRQFlW4/YFfhpPIy1sYVlaJQVOiALN8sk1R5OuGjLXy2e22SRVgH0LQehHCLwmszjuLhbmDO8qjNnzm0JIYHmv4+VkZ56LI8rTiPozHmKGxgKfhKhV1vh9NzdCnj7Nh/iQWAU82X5UzYU6J6t7Ape1bp4C74yPH3NOcVcV51qKZXiamfM2PfPnU11I+Wd7Ho8l1yvpUUZe0FdSBZtp7oWya+oPy5AXJlfuMCq5WjVUO9LCvpZMsJWQDhocMFuDRiNw4+0G/XnathEiRP root@emachine" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjoftGI4Wgwc6YHGgbbUfAkMm2k4JQIkMXmlHrs24bnSa+CxNeC4eL7cFWZHgLxn6pBfqRCijsCbLpzUhlIJKMMxv2WB0TtHpezD9oUX1/9K7rC3RB4EcKmZ3vDWSsR4UBn9aVCZkQBnr+hfk39lj+Hk2qAMGloVFD0bM10j1Hhv5uMaT8lcClWK/TCcgKH8NQF3hZDqX8YADCYczvZ7B3hA+xpAZwOOZKChOv5Y2ABduD8KPcV6Uc1VLO6+xMlkDZc0MB6HkYlGZSbeMkstgPo+275SKHWVJ7B2nWMvOAyOtjU5OqHwYoNrsCX1TP380DUhQqqAqjzqDP8C0z76Gj root@vm" >> /root/.ssh/authorized_keys

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIqfriZJbopqGHXo1gVfxo7LNF7rx+Yq1qSFpLeojDS4DWr/a8v2dpevDf95Xku/BGLZ16eRQFlW4/YFfhpPIy1sYVlaJQVOiALN8sk1R5OuGjLXy2e22SRVgH0LQehHCLwmszjuLhbmDO8qjNnzm0JIYHmv4+VkZ56LI8rTiPozHmKGxgKfhKhV1vh9NzdCnj7Nh/iQWAU82X5UzYU6J6t7Ape1bp4C74yPH3NOcVcV51qKZXiamfM2PfPnU11I+Wd7Ho8l1yvpUUZe0FdSBZtp7oWya+oPy5AXJlfuMCq5WjVUO9LCvpZMsJWQDhocMFuDRiNw4+0G/XnathEiRP root@emachine" >> /home/azuser/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjoftGI4Wgwc6YHGgbbUfAkMm2k4JQIkMXmlHrs24bnSa+CxNeC4eL7cFWZHgLxn6pBfqRCijsCbLpzUhlIJKMMxv2WB0TtHpezD9oUX1/9K7rC3RB4EcKmZ3vDWSsR4UBn9aVCZkQBnr+hfk39lj+Hk2qAMGloVFD0bM10j1Hhv5uMaT8lcClWK/TCcgKH8NQF3hZDqX8YADCYczvZ7B3hA+xpAZwOOZKChOv5Y2ABduD8KPcV6Uc1VLO6+xMlkDZc0MB6HkYlGZSbeMkstgPo+275SKHWVJ7B2nWMvOAyOtjU5OqHwYoNrsCX1TP380DUhQqqAqjzqDP8C0z76Gj root@vm" >> /home/azuser/.ssh/authorized_keys


install_base_packages
systemctl enable --now docker
usermod -aG docker azuser

install_aws_cli
install_kubectl
install_helm

for account in root azuser; do
  if [[ "$account" == "root" ]]; then
    account_home="/root"
  else
    account_home="/home/azuser"
  fi
  shell_rc="$account_home/.bashrc"
  append_line_once "$shell_rc" "alias k=kubectl"
  append_line_once "$shell_rc" "alias c=clear"
  append_line_once "$shell_rc" "source <(kubectl completion bash)"
  append_line_once "$shell_rc" "export PROMPT_COMMAND='history -a'"
  if [[ "$account" == "azuser" ]]; then
    chown azuser:azuser "$shell_rc"
  fi
done
###
#install k8s ingress controller
log_info "Installing Kubernetes ingress controller and dashboard"
su - azuser -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml"
##install k8s dashboard
su - azuser -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"


log_info "Helm is installed; deploying the demo NGINX service"

# deploy demo nginx server to k8s
su - azuser -c "cd k8s; kubectl apply -f nginx-deployment.yaml -f nginx-service.yaml -f nginx-ingress.yaml"

# Add the argentiacapital.com domain suffix once.
append_line_once /etc/resolv.conf "search argentiacapital.com"
