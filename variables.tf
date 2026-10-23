variable "environment" {
  type        = string
  description = "Deployment environment name."

  validation {
    condition     = contains(["prod", "nprod", "dev", "test", "sbx", "lab"], var.environment)
    error_message = "environment must be one of: prod, nprod, dev, test, sbx, lab."
  }
}

variable "location" {
  type        = string
  description = "Azure region for resources in this environment."
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription targeted by the AzureRM provider."

  validation {
    condition     = can(regex("^[0-9a-fA-F-]{36}$", var.subscription_id))
    error_message = "subscription_id must be a GUID."
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Tags applied to resources in this environment."
}

variable "inherit_resource_group_tags" {
  type        = bool
  description = "Whether service modules should inherit the resource group tag map."
}

variable "app_admin_group" {
  type        = list(string)
  description = "Optional Entra groups or object IDs granted Contributor access."
}

variable "app_user_group" {
  type        = list(string)
  description = "Optional Entra groups or object IDs granted Reader access."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group created for this deployment."

  validation {
    condition     = trimspace(var.resource_group_name) != ""
    error_message = "resource_group_name must not be empty."
  }
}

variable "resource_group_enable_lock" {
  type        = bool
  description = "Whether the resource group module applies a delete lock."
}

variable "virtual_network_name" {
  type        = string
  description = "Name of the virtual network."
}

variable "virtual_network_address_space" {
  type        = list(string)
  description = "Address spaces assigned to the virtual network."
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet used by AKS and the jumpbox."
}

variable "subnets" {
  type = map(object({
    address_prefixes = list(string)
  }))
  description = "Subnet definitions keyed by subnet name."
}

variable "network_security_group_name" {
  type        = string
  description = "Name of the jumpbox network security group."
}

variable "network_security_rules" {
  type = map(object({
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
    description                = string
  }))
  description = "Network security rules keyed by rule name."

  validation {
    condition = try(
      can(cidrnetmask(var.network_security_rules["SSH"].source_address_prefix)) &&
      tonumber(split("/", var.network_security_rules["SSH"].source_address_prefix)[1]) >= 24,
      false
    )
    error_message = "network_security_rules.SSH.source_address_prefix must be a valid IPv4 CIDR with a /24 or narrower range (preferably a single address with /32)."
  }
}

variable "public_ip_name" {
  type        = string
  description = "Name of the jumpbox public IP."
}

variable "public_ip_allocation_method" {
  type        = string
  description = "Allocation method for the jumpbox public IP."
}

variable "network_interface_name" {
  type        = string
  description = "Name of the jumpbox network interface."
}

variable "network_interface_ip_configuration_name" {
  type        = string
  description = "Name of the jumpbox NIC IP configuration."
}

variable "private_ip_address_allocation" {
  type        = string
  description = "Private IP allocation mode for the jumpbox NIC."
}

variable "virtual_machine_name" {
  type        = string
  description = "Azure name of the jumpbox virtual machine."
}

variable "virtual_machine_computer_name" {
  type        = string
  description = "Operating system computer name for the jumpbox."
}

variable "virtual_machine_size" {
  type        = string
  description = "Azure VM size for the jumpbox."
}

variable "virtual_machine_admin_username" {
  type        = string
  description = "Linux administrator account name for the jumpbox."
}

variable "virtual_machine_disable_password_authentication" {
  type        = bool
  description = "Whether Linux password authentication is disabled."
}

variable "vm_os_family" {
  type        = string
  description = "Linux distribution family selected from vm_images: ubuntu or redhat."

  validation {
    condition     = contains(keys(var.vm_images), var.vm_os_family)
    error_message = "vm_os_family must be a key in vm_images (for example, ubuntu or redhat)."
  }
}

variable "vm_images" {
  type = map(object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  }))
  description = "Marketplace image definitions keyed by Linux distribution family."
}

variable "os_disk_name" {
  type        = string
  description = "Name of the jumpbox OS disk."
}

variable "os_disk_caching" {
  type        = string
  description = "Caching mode for the jumpbox OS disk."
}

variable "os_disk_storage_account_type" {
  type        = string
  description = "Storage SKU for the jumpbox OS disk."
}

variable "os_disk_size_gb" {
  type        = number
  description = "Size of the jumpbox OS disk in GiB."
}

variable "virtual_machine_user_data_script" {
  type        = string
  description = "Path relative to the repository root for the jumpbox bootstrap script."
}

variable "virtual_machine_remote_commands" {
  type        = list(string)
  description = "Commands run over SSH after the jumpbox is provisioned."
}

variable "ssh_connection_timeout" {
  type        = string
  description = "Terraform SSH provisioner connection timeout."
}

variable "kubeconfig_file_path" {
  type        = string
  description = "Local path where the AKS kubeconfig is written and read by the VM provisioner."
}

variable "virtual_machine_kubeconfig_destination" {
  type        = string
  description = "Remote path for the kubeconfig on the jumpbox."
}

variable "k8s_files_path" {
  type        = string
  description = "Local directory copied to the jumpbox."
}

variable "virtual_machine_k8s_files_destination" {
  type        = string
  description = "Remote destination directory for the Kubernetes demo files."
}

variable "ssh_key_algorithm" {
  type        = string
  description = "Algorithm used to generate the jumpbox SSH key pair."
}

variable "ssh_rsa_bits" {
  type        = number
  description = "RSA key size when ssh_key_algorithm is RSA."
}

variable "ssh_private_key_path" {
  type        = string
  description = "Local path where Terraform writes the generated private SSH key."
}

variable "ssh_public_key_path" {
  type        = string
  description = "Local path where Terraform writes the generated public SSH key."
}

variable "emachine_ssh_key_name" {
  type        = string
  description = "Azure SSH key resource name for the emachine public key."
}

variable "emachine_public_key" {
  type        = string
  description = "SSH public key registered for the emachine account."
}

variable "vm_ssh_key_name" {
  type        = string
  description = "Azure SSH key resource name for the VM public key."
}

variable "vm_public_key" {
  type        = string
  description = "SSH public key registered for the VM account."
}

variable "aks_name" {
  type        = string
  description = "AKS cluster name."
}

variable "aks_workload_name" {
  type        = string
  description = "Short workload name used by the AKS module for generated naming."
}

variable "aks_dns_prefix" {
  type        = string
  description = "DNS prefix for the AKS API server."
}

variable "aks_kubernetes_version" {
  type        = string
  description = "Optional Kubernetes version; null lets Azure choose its default."
}

variable "aks_sku_tier" {
  type        = string
  description = "AKS SKU tier."
}

variable "aks_automatic_upgrade_channel" {
  type        = string
  description = "AKS automatic upgrade channel."
}

variable "aks_private_cluster_enabled" {
  type        = bool
  description = "Whether the AKS API server is private."
}

variable "aks_role_based_access_control_enabled" {
  type        = bool
  description = "Whether Kubernetes RBAC is enabled."
}

variable "aks_azure_rbac_enabled" {
  type        = bool
  description = "Whether Azure RBAC is used for Kubernetes authorization."
}

variable "aks_local_account_disabled" {
  type        = bool
  description = "Whether local Kubernetes accounts are disabled."
}

variable "aks_oidc_issuer_enabled" {
  type        = bool
  description = "Whether the AKS OIDC issuer is enabled."
}

variable "aks_workload_identity_enabled" {
  type        = bool
  description = "Whether AKS Workload Identity is enabled."
}

variable "aks_subnet_name" {
  type        = string
  description = "Subnet key from subnets used by the AKS default node pool."
}

variable "aks_default_node_pool" {
  type = object({
    name                   = string
    vm_size                = string
    node_count             = number
    auto_scaling_enabled   = bool
    node_public_ip_enabled = bool
    type                   = string
  })
  description = "AKS default system node pool settings."
}

variable "aks_network_profile" {
  type = object({
    network_plugin      = string
    network_plugin_mode = string
    network_policy      = string
    network_data_plane  = string
    load_balancer_sku   = string
    outbound_type       = string
  })
  description = "AKS network profile settings."
}

variable "aks_tags" {
  type        = map(string)
  description = "Additional tags for AKS resources."
}

variable "dns_zone" {
  type = object({
    enabled             = bool
    name                = string
    resource_group_name = string
    demo_ipv4           = string
    node1_ipv4          = string
    endpoint_ipv4       = string
  })
  description = "Optional existing Azure DNS zone and static IPv4 targets for its manually managed AKS records."

  validation {
    condition = !var.dns_zone.enabled || (
      trimspace(var.dns_zone.name) != "" &&
      trimspace(var.dns_zone.resource_group_name) != "" &&
      can(cidrnetmask("${var.dns_zone.demo_ipv4}/32")) &&
      can(cidrnetmask("${var.dns_zone.node1_ipv4}/32")) &&
      can(cidrnetmask("${var.dns_zone.endpoint_ipv4}/32"))
    )
    error_message = "When dns_zone.enabled is true, provide the existing zone name, its resource group, and valid IPv4 addresses for demo_ipv4, node1_ipv4, and endpoint_ipv4."
  }
}

variable "dns_record_names" {
  type = object({
    jumpbox  = string
    api      = string
    demo     = string
    node1    = string
    endpoint = string
  })
  description = "DNS record names managed when dns_zone.enabled is true."
}

variable "dns_record_ttl" {
  type        = number
  description = "TTL in seconds for managed DNS records."
}

variable "vm_delete_os_disk_on_deletion" {
  type        = bool
  description = "Whether deleting a Linux VM also deletes its OS disk."
}
