# Development environment values. Replace the documentation-only SSH CIDR
# with a trusted public IPv4 CIDR before planning or applying.
environment     = "dev"
location        = "canadacentral"
subscription_id = "1ec5edd4-5654-4246-8027-b29ef63b3393"
common_tags = {
  managed_by_terraform = "true"
  terraform_project    = "https://github.com/andyxuan2010/AIonK8sDemo"
  owner_group          = "TBD"
  cost_center          = "TBD"
  technical_contact    = "andyxuan2010@gmail.com"
  tenant_owner         = "andyxuan2010@gmail.com"
  creation_date        = "2023-07-02"
  project              = "azure-k8s-demo"
  region               = "canadacentral"
  purpose              = "demo"
  resource_group_name  = "rg-platform-dev"
}
inherit_resource_group_tags = false
app_admin_group             = []
app_user_group              = []

# Foundation modules
resource_group_name        = "challenge2-rg"
resource_group_enable_lock = false

virtual_network_name          = "challenge2-vnet"
virtual_network_address_space = ["10.10.0.0/16"]
subnet_name                   = "challenge2-subnet"
subnets = {
  challenge2-subnet = {
    address_prefixes = ["10.10.1.0/24"]
  }
}

network_security_group_name = "nsg-k8s"
network_security_rules = {
  SSH = {
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "203.0.113.10/32"
    destination_address_prefix = "*"
    description                = "SSH from the approved administration range."
  }
}

# Jumpbox settings
public_ip_name                                  = "pip-k8s"
public_ip_allocation_method                     = "Static"
network_interface_name                          = "nic-k8s"
network_interface_ip_configuration_name         = "myNicConfiguration"
private_ip_address_allocation                   = "Dynamic"
virtual_machine_name                            = "vm-k8s"
virtual_machine_computer_name                   = "vm-k8s"
virtual_machine_size                            = "Standard_B1s"
virtual_machine_admin_username                  = "azuser"
virtual_machine_disable_password_authentication = true
vm_os_family                                    = "ubuntu"
vm_images = {
  ubuntu = {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  redhat = {
    publisher = "RedHat"
    offer     = "RHEL"
    sku       = "9-lvm-gen2"
    version   = "latest"
  }
}
os_disk_name                     = "linuxvmOsDisk-vm-k8s"
os_disk_caching                  = "ReadWrite"
os_disk_storage_account_type     = "Standard_LRS"
os_disk_size_gb                  = 40
virtual_machine_user_data_script = "scripts/userdata-linux.sh"
virtual_machine_remote_commands = [
  "mkdir -p ~/.kube/",
  "mkdir -p /home/azuser/.kube/",
]
ssh_connection_timeout                 = "10m"
kubeconfig_file_path                   = "../k8s/.kube/config"
virtual_machine_kubeconfig_destination = "/home/azuser/.kube/config"
k8s_files_path                         = "../k8s"
virtual_machine_k8s_files_destination  = "/home/azuser"

# SSH files and Azure SSH public key resources
ssh_key_algorithm     = "RSA"
ssh_rsa_bits          = 2048
ssh_private_key_path  = "../id_rsa"
ssh_public_key_path   = "../id_rsa.pub"
emachine_ssh_key_name = "emachine-pub-key"
emachine_public_key   = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDIqfriZJbopqGHXo1gVfxo7LNF7rx+Yq1qSFpLeojDS4DWr/a8v2dpevDf95Xku/BGLZ16eRQFlW4/YFfhpPIy1sYVlaJQVOiALN8sk1R5OuGjLXy2e22SRVgH0LQehHCLwmszjuLhbmDO8qjNnzm0JIYHmv4+VkZ56LI8rTiPozHmKGxgKfhKhV1vh9NzdCnj7Nh/iQWAU82X5UzYU6J6t7Ape1bp4C74yPH3NOcVcV51qKZXiamfM2PfPnU11I+Wd7Ho8l1yvpUUZe0FdSBZtp7oWya+oPy5AXJlfuMCq5WjVUO9LCvpZMsJWQDhocMFuDRiNw4+0G/XnathEiRP root@emachine"
vm_ssh_key_name       = "vm-pub-key"
vm_public_key         = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjoftGI4Wgwc6YHGgbbUfAkMm2k4JQIkMXmlHrs24bnSa+CxNeC4eL7cFWZHgLxn6pBfqRCijsCbLpzUhlIJKMMxv2WB0TtHpezD9oUX1/9K7rC3RB4EcKmZ3vDWSsR4UBn9aVCZkQBnr+hfk39lj+Hk2qAMGloVFD0bM10j1Hhv5uMaT8lcClWK/TCcgKH8NQF3hZDqX8YADCYczvZ7B3hA+xpAZwOOZKChOv5Y2ABduD8KPcV6Uc1VLO6+xMlkDZc0MB6HkYlGZSbeMkstgPo+275SKHWVJ7B2nWMvOAyOtjU5OqHwYoNrsCX1TP380DUhQqqAqjzqDP8C0z76Gj root@vm"

# AKS module settings
aks_name                              = "challenge-aks"
aks_workload_name                     = "challenge"
aks_dns_prefix                        = "basf"
aks_kubernetes_version                = null
aks_sku_tier                          = "Free"
aks_automatic_upgrade_channel         = "patch"
aks_private_cluster_enabled           = false
aks_role_based_access_control_enabled = true
aks_azure_rbac_enabled                = false
aks_local_account_disabled            = false
aks_oidc_issuer_enabled               = false
aks_workload_identity_enabled         = false
aks_subnet_name                       = "challenge2-subnet"
aks_default_node_pool = {
  name                   = "system"
  vm_size                = "standard_b2s"
  node_count             = 1
  auto_scaling_enabled   = false
  node_public_ip_enabled = false
  type                   = "VirtualMachineScaleSets"
}
aks_network_profile = {
  network_plugin      = "azure"
  network_plugin_mode = "overlay"
  network_policy      = null
  network_data_plane  = null
  load_balancer_sku   = "standard"
  outbound_type       = "loadBalancer"
}
aks_tags = {}

# Optional DNS zone integration
dns_zone = {
  enabled             = false
  name                = ""
  resource_group_name = ""
  demo_ipv4           = ""
  node1_ipv4          = ""
  endpoint_ipv4       = ""
}
dns_record_names = {
  jumpbox  = "k8s"
  api      = "api"
  demo     = "demo"
  node1    = "n1"
  endpoint = "ep"
}
dns_record_ttl = 300

vm_delete_os_disk_on_deletion = true
