module "resource_group" {
  source = "git::https://github.com/andyxuan2010/azure-template.git//modules/rg?ref=main"

  name            = var.resource_group_name
  location        = var.location
  app_env         = var.environment
  enable_lock     = var.resource_group_enable_lock
  app_admin_group = var.app_admin_group
  app_user_group  = var.app_user_group
  tags            = local.rg_tags
}

module "virtual_network" {
  source = "git::https://github.com/andyxuan2010/azure-template.git//modules/vnet?ref=main"

  name                          = var.virtual_network_name
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  address_space                 = var.virtual_network_address_space
  subnets                       = var.subnets
  app_admin_group               = var.app_admin_group
  app_user_group                = var.app_user_group
  inherit_resource_group_tags   = var.inherit_resource_group_tags
  inherited_resource_group_tags = local.rg_tags
  tags = merge(var.common_tags, {
    name = var.virtual_network_name
  })
}

module "network_security_group" {
  source = "git::https://github.com/andyxuan2010/azure-template.git//modules/nsg?ref=main"

  name                = var.network_security_group_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  security_rules      = var.network_security_rules
  network_interface_associations = {
    (var.network_interface_name) = azurerm_network_interface.nic-k8s.id
  }
  inherit_resource_group_tags   = var.inherit_resource_group_tags
  inherited_resource_group_tags = local.rg_tags
  tags                          = var.common_tags
}

module "aks" {
  source = "git::https://github.com/andyxuan2010/azure-template.git//modules/aks?ref=main"

  name                = var.aks_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  app_env             = var.environment
  workload_name       = var.aks_workload_name
  dns_prefix          = var.aks_dns_prefix

  kubernetes_version        = var.aks_kubernetes_version
  sku_tier                  = var.aks_sku_tier
  automatic_upgrade_channel = var.aks_automatic_upgrade_channel

  private_cluster_enabled           = var.aks_private_cluster_enabled
  role_based_access_control_enabled = var.aks_role_based_access_control_enabled
  azure_rbac_enabled                = var.aks_azure_rbac_enabled
  local_account_disabled            = var.aks_local_account_disabled
  oidc_issuer_enabled               = var.aks_oidc_issuer_enabled
  workload_identity_enabled         = var.aks_workload_identity_enabled
  app_admin_group                   = var.app_admin_group
  app_user_group                    = var.app_user_group
  default_node_pool = merge(var.aks_default_node_pool, {
    vnet_subnet_id = module.virtual_network.subnet_ids[var.aks_subnet_name]
  })
  network_profile = merge(var.aks_network_profile, {
    # AKS supports plugin modes such as overlay only with the Azure CNI plugin.
    # Ignore a stale overlay value when Kubenet is selected.
    network_plugin_mode = var.aks_network_profile.network_plugin == "azure" ? var.aks_network_profile.network_plugin_mode : null
  })

  inherit_resource_group_tags   = var.inherit_resource_group_tags
  inherited_resource_group_tags = local.rg_tags
  tags                          = var.aks_tags
}

# The module intentionally does not expose kube_config_raw. Read it through
# the provider data source so the existing kubeconfig file workflow is retained.
data "azurerm_kubernetes_cluster" "aks" {
  name                = module.aks.name
  resource_group_name = module.aks.resource_group_name
  depends_on          = [module.aks]
}

# Preserve existing Terraform state addresses while ownership moves into modules.
moved {
  from = azurerm_resource_group.challenge2-rg
  to   = module.resource_group.azurerm_resource_group.this
}

moved {
  from = azurerm_virtual_network.challenge2-vnet
  to   = module.virtual_network.azurerm_virtual_network.this
}

moved {
  from = azurerm_subnet.challenge2-subnet
  to   = module.virtual_network.azurerm_subnet.this["challenge2-subnet"]
}

moved {
  from = azurerm_network_security_group.nsg-k8s
  to   = module.network_security_group.azurerm_network_security_group.this
}

moved {
  from = azurerm_network_interface_security_group_association.association
  to   = module.network_security_group.azurerm_network_interface_security_group_association.by_name["nic-k8s"]
}

moved {
  from = azurerm_kubernetes_cluster.aks
  to   = module.aks.azurerm_kubernetes_cluster.this
}

resource "azurerm_public_ip" "pip-k8s" {
  name                = var.public_ip_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  allocation_method   = var.public_ip_allocation_method
}

resource "azurerm_network_interface" "nic-k8s" {
  name                = var.network_interface_name
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name

  ip_configuration {
    name                          = var.network_interface_ip_configuration_name
    subnet_id                     = module.virtual_network.subnet_ids[var.subnet_name]
    private_ip_address_allocation = var.private_ip_address_allocation
    public_ip_address_id          = azurerm_public_ip.pip-k8s.id
  }
}

resource "azurerm_linux_virtual_machine" "vm-k8s" {
  name                  = var.virtual_machine_name
  computer_name         = var.virtual_machine_computer_name
  location              = module.resource_group.location
  resource_group_name   = module.resource_group.name
  size                  = var.virtual_machine_size
  network_interface_ids = [azurerm_network_interface.nic-k8s.id]

  os_disk {
    name                 = var.os_disk_name
    caching              = var.os_disk_caching
    storage_account_type = var.os_disk_storage_account_type
    disk_size_gb         = var.os_disk_size_gb
  }

  source_image_reference {
    publisher = local.vm_image.publisher
    offer     = local.vm_image.offer
    sku       = local.vm_image.sku
    version   = local.vm_image.version
  }

  admin_username                  = var.virtual_machine_admin_username
  disable_password_authentication = var.virtual_machine_disable_password_authentication

  admin_ssh_key {
    username   = var.virtual_machine_admin_username
    public_key = tls_private_key.global-key.public_key_openssh
  }

  custom_data = base64encode(join("", [
    "#!/usr/bin/env bash\n",
    "export KUBECTL_VERSION=\"v${module.aks.kubernetes_version}\"\n",
    file("${path.module}/../${var.virtual_machine_user_data_script}")
  ]))

  provisioner "remote-exec" {
    inline = var.virtual_machine_remote_commands

    connection {
      type        = "ssh"
      user        = var.virtual_machine_admin_username
      private_key = tls_private_key.global-key.private_key_pem
      host        = self.public_ip_address
      timeout     = var.ssh_connection_timeout
    }
  }

  provisioner "file" {
    source      = var.kubeconfig_file_path
    destination = var.virtual_machine_kubeconfig_destination

    connection {
      type        = "ssh"
      user        = var.virtual_machine_admin_username
      private_key = tls_private_key.global-key.private_key_pem
      host        = self.public_ip_address
      timeout     = var.ssh_connection_timeout
    }
  }

  provisioner "file" {
    source      = var.k8s_files_path
    destination = var.virtual_machine_k8s_files_destination

    connection {
      type        = "ssh"
      user        = var.virtual_machine_admin_username
      private_key = tls_private_key.global-key.private_key_pem
      host        = self.public_ip_address
      timeout     = var.ssh_connection_timeout
    }
  }

  depends_on = [local_sensitive_file.kubeconfig]
}

resource "tls_private_key" "global-key" {
  algorithm = var.ssh_key_algorithm
  rsa_bits  = var.ssh_rsa_bits
}

resource "local_sensitive_file" "ssh-private-key-pem" {
  filename        = var.ssh_private_key_path
  content         = tls_private_key.global-key.private_key_pem
  file_permission = "0600"
}

resource "local_file" "ssh-public-key-openssh" {
  filename = var.ssh_public_key_path
  content  = tls_private_key.global-key.public_key_openssh
}

resource "local_sensitive_file" "kubeconfig" {
  filename        = var.kubeconfig_file_path
  content         = data.azurerm_kubernetes_cluster.aks.kube_config_raw
  file_permission = "0600"
}

resource "azurerm_ssh_public_key" "emachine-pub-key" {
  name                = var.emachine_ssh_key_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  public_key          = var.emachine_public_key
}

resource "azurerm_ssh_public_key" "vm-pub-key" {
  name                = var.vm_ssh_key_name
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  public_key          = var.vm_public_key
}

data "azurerm_dns_zone" "configured" {
  count               = var.dns_zone.enabled ? 1 : 0
  name                = var.dns_zone.name
  resource_group_name = var.dns_zone.resource_group_name
}

resource "azurerm_dns_a_record" "k8s" {
  count               = var.dns_zone.enabled ? 1 : 0
  name                = var.dns_record_names.jumpbox
  zone_name           = data.azurerm_dns_zone.configured[0].name
  resource_group_name = data.azurerm_dns_zone.configured[0].resource_group_name
  ttl                 = var.dns_record_ttl
  records             = [azurerm_linux_virtual_machine.vm-k8s.public_ip_address]
}

resource "azurerm_dns_cname_record" "api" {
  count               = var.dns_zone.enabled ? 1 : 0
  name                = var.dns_record_names.api
  zone_name           = data.azurerm_dns_zone.configured[0].name
  resource_group_name = data.azurerm_dns_zone.configured[0].resource_group_name
  ttl                 = var.dns_record_ttl
  record              = module.aks.fqdn
}

resource "azurerm_dns_a_record" "demo" {
  count               = var.dns_zone.enabled ? 1 : 0
  name                = var.dns_record_names.demo
  zone_name           = data.azurerm_dns_zone.configured[0].name
  resource_group_name = data.azurerm_dns_zone.configured[0].resource_group_name
  ttl                 = var.dns_record_ttl
  records             = [var.dns_zone.demo_ipv4]
}

resource "azurerm_dns_a_record" "n1" {
  count               = var.dns_zone.enabled ? 1 : 0
  name                = var.dns_record_names.node1
  zone_name           = data.azurerm_dns_zone.configured[0].name
  resource_group_name = data.azurerm_dns_zone.configured[0].resource_group_name
  ttl                 = var.dns_record_ttl
  records             = [var.dns_zone.node1_ipv4]
}

resource "azurerm_dns_a_record" "ep" {
  count               = var.dns_zone.enabled ? 1 : 0
  name                = var.dns_record_names.endpoint
  zone_name           = data.azurerm_dns_zone.configured[0].name
  resource_group_name = data.azurerm_dns_zone.configured[0].resource_group_name
  ttl                 = var.dns_record_ttl
  records             = [var.dns_zone.endpoint_ipv4]
}
