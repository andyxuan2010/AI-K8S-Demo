#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_VERSION="1.0.0"
SCRIPT_NAME="userdata-ubuntu"
SCRIPT_LOG_FILE="${BOOTSTRAP_LOG_FILE:-/var/log/aks-vm-bootstrap.log}"
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
log_info "Log file: $SCRIPT_LOG_FILE"

ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime

#add argentiacapital.com domain suffix to the vm
echo "search argentiacapital.com" >> /etc/resolv.conf

#add additional keepalive seconds to sshd
echo "ClientAliveInterval 1200" >> /etc/ssh/sshd_config
echo "ClientAliveCountMax  3" >> /etc/ssh/sshd_config
#sed -i -E 's/#?PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# install emachine key and vm key
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIqfriZJbopqGHXo1gVfxo7LNF7rx+Yq1qSFpLeojDS4DWr/a8v2dpevDf95Xku/BGLZ16eRQFlW4/YFfhpPIy1sYVlaJQVOiALN8sk1R5OuGjLXy2e22SRVgH0LQehHCLwmszjuLhbmDO8qjNnzm0JIYHmv4+VkZ56LI8rTiPozHmKGxgKfhKhV1vh9NzdCnj7Nh/iQWAU82X5UzYU6J6t7Ape1bp4C74yPH3NOcVcV51qKZXiamfM2PfPnU11I+Wd7Ho8l1yvpUUZe0FdSBZtp7oWya+oPy5AXJlfuMCq5WjVUO9LCvpZMsJWQDhocMFuDRiNw4+0G/XnathEiRP root@emachine" >> /root/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjoftGI4Wgwc6YHGgbbUfAkMm2k4JQIkMXmlHrs24bnSa+CxNeC4eL7cFWZHgLxn6pBfqRCijsCbLpzUhlIJKMMxv2WB0TtHpezD9oUX1/9K7rC3RB4EcKmZ3vDWSsR4UBn9aVCZkQBnr+hfk39lj+Hk2qAMGloVFD0bM10j1Hhv5uMaT8lcClWK/TCcgKH8NQF3hZDqX8YADCYczvZ7B3hA+xpAZwOOZKChOv5Y2ABduD8KPcV6Uc1VLO6+xMlkDZc0MB6HkYlGZSbeMkstgPo+275SKHWVJ7B2nWMvOAyOtjU5OqHwYoNrsCX1TP380DUhQqqAqjzqDP8C0z76Gj root@vm" >> /root/.ssh/authorized_keys

echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIqfriZJbopqGHXo1gVfxo7LNF7rx+Yq1qSFpLeojDS4DWr/a8v2dpevDf95Xku/BGLZ16eRQFlW4/YFfhpPIy1sYVlaJQVOiALN8sk1R5OuGjLXy2e22SRVgH0LQehHCLwmszjuLhbmDO8qjNnzm0JIYHmv4+VkZ56LI8rTiPozHmKGxgKfhKhV1vh9NzdCnj7Nh/iQWAU82X5UzYU6J6t7Ape1bp4C74yPH3NOcVcV51qKZXiamfM2PfPnU11I+Wd7Ho8l1yvpUUZe0FdSBZtp7oWya+oPy5AXJlfuMCq5WjVUO9LCvpZMsJWQDhocMFuDRiNw4+0G/XnathEiRP root@emachine" >> /home/azuser/.ssh/authorized_keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjoftGI4Wgwc6YHGgbbUfAkMm2k4JQIkMXmlHrs24bnSa+CxNeC4eL7cFWZHgLxn6pBfqRCijsCbLpzUhlIJKMMxv2WB0TtHpezD9oUX1/9K7rC3RB4EcKmZ3vDWSsR4UBn9aVCZkQBnr+hfk39lj+Hk2qAMGloVFD0bM10j1Hhv5uMaT8lcClWK/TCcgKH8NQF3hZDqX8YADCYczvZ7B3hA+xpAZwOOZKChOv5Y2ABduD8KPcV6Uc1VLO6+xMlkDZc0MB6HkYlGZSbeMkstgPo+275SKHWVJ7B2nWMvOAyOtjU5OqHwYoNrsCX1TP380DUhQqqAqjzqDP8C0z76Gj root@vm" >> /home/azuser/.ssh/authorized_keys


log_info "Updating Ubuntu packages and installing VM tools"
apt-get update -y
apt-get upgrade -y

apt-get -y install net-tools nmap unzip jq golang golang-go docker docker-compose nfs-common binutils bash-completion
export PATH=$PATH:/usr/local/go/bin
usermod -aG docker azuser
systemctl enable docker
systemctl start docker

source /etc/profile.d/bash_completion.sh
echo "export PROMPT_COMMAND='history -a'" >> /etc/bashrc


#install aws cli version2
# just in case apt-get fails to install
if [ -x "$(command -v aws)" ]; then
    echo "AWS CLI is already installed."
else
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip > /dev/null
    ./aws/install
fi



#install kubectl
apt-get install -y apt-transport-https
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-archive-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubectl
#snap install -y kubectl

echo "alias k=kubectl" >> /home/azuser/.bashrc
echo "alias c=clear" >> /home/azuser/.bashrc
echo "source <(kubectl completion bash)" >> /home/azuser/.bashrc
echo "alias k=kubectl" >> /root/.bashrc
echo "alias c=clear" >> /root/.bashrc
echo "source <(kubectl completion bash)" >> /root/.bashrc
source /home/azuser/.bashrc
source /root/.bashrc

###
#install k8s ingress controller
log_info "Installing Kubernetes ingress controller and dashboard"
su - azuser -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml"
##install k8s dashboard
su - azuser -c "kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml"


# install helm package
log_info "Installing Helm and deploying the demo NGINX service"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
apt-get update
apt-get install -y helm

# deploy demo nginx server to k8s
su - azuser -c "cd k8s; kubectl apply -f nginx-deployment.yaml -f nginx-service.yaml -f nginx-ingress.yaml" 

#add argentiacapital.com domain suffix to the vm
echo "search argentiacapital.com" >> /etc/resolv.conf
