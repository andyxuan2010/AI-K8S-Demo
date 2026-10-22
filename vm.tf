# Create public IPs
resource "azurerm_public_ip" "pip-k8s" {
  name                = "pip-k8s"
  location            = azurerm_resource_group.challenge2-rg.location
  resource_group_name = azurerm_resource_group.challenge2-rg.name
  #allocation_method   = "Dynamic"
  allocation_method = "Static"
}

# resource "azurerm_public_ip" "pip-api" {
#   name                = "pip-api"
#   location            = azurerm_resource_group.challenge2-rg.location
#   resource_group_name = azurerm_resource_group.challenge2-rg.name
#   allocation_method   = "Static"
# }


# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg-k8s" {
  name                = "nsg-k8s"
  location            = azurerm_resource_group.challenge2-rg.location
  resource_group_name = azurerm_resource_group.challenge2-rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

# Create network interface
resource "azurerm_network_interface" "nic-k8s" {
  name                = "nic-k8s"
  location            = azurerm_resource_group.challenge2-rg.location
  resource_group_name = azurerm_resource_group.challenge2-rg.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.challenge2-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-k8s.id
  }
  depends_on = [azurerm_public_ip.pip-k8s]

}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "association" {
  network_interface_id      = azurerm_network_interface.nic-k8s.id
  network_security_group_id = azurerm_network_security_group.nsg-k8s.id
}

resource "azurerm_linux_virtual_machine" "vm-k8s" {
  name                  = "vm-k8s"
  location              = azurerm_resource_group.challenge2-rg.location
  resource_group_name   = azurerm_resource_group.challenge2-rg.name
  network_interface_ids = [azurerm_network_interface.nic-k8s.id]
  #size                  = "Standard_DS1_v2"
  size = "Standard_B1s"

  os_disk {
    name                 = "linuxvmOsDisk-vm-k8s"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 40
  }

  source_image_reference {
    publisher = var.vm_os_family == "redhat" ? "RedHat" : "Canonical"
    offer     = var.vm_os_family == "redhat" ? "RHEL" : "0001-com-ubuntu-server-jammy"
    sku       = var.vm_os_family == "redhat" ? "9-lvm-gen2" : "22_04-lts-gen2"
    version   = "latest"
  }

  # delete_data_disks_on_termination = true
  # delete_os_disk_on_termination = true

  computer_name                   = "vm-k8s"
  admin_username                  = "azuser"
  disable_password_authentication = true
  admin_ssh_key {
    username = "azuser"
    #public_key = azurerm_ssh_public_key.vm-pub-key.public_key
    public_key = tls_private_key.global-key.public_key_openssh
  }
  custom_data = base64encode(join("", [
    "#!/usr/bin/env bash\n",
    "export KUBECTL_VERSION=\"v${azurerm_kubernetes_cluster.aks.kubernetes_version}\"\n",
    file("${path.module}/scripts/userdata-linux.sh")
  ]))


  provisioner "remote-exec" {
    inline = [
      "mkdir -p ~/.kube/",
      "mkdir -p /home/azuser/.kube/"
    ]
    connection {
      type        = "ssh"
      user        = "azuser"
      private_key = tls_private_key.global-key.private_key_pem
      host        = self.public_ip_address
      timeout     = 10
    }
  }

  provisioner "file" {
    source      = "${path.module}/k8s/.kube/config"
    destination = "/home/azuser/.kube/config"
    connection {
      type        = "ssh"
      user        = "azuser"
      private_key = tls_private_key.global-key.private_key_pem
      host        = self.public_ip_address
      timeout     = 10
    }
  }

  provisioner "file" {
    source      = "${path.module}/k8s"
    destination = "/home/azuser"
    connection {
      type        = "ssh"
      user        = "azuser"
      private_key = tls_private_key.global-key.private_key_pem
      host        = self.public_ip_address
      timeout     = 10
    }
  }

  depends_on = [azurerm_kubernetes_cluster.aks, azurerm_network_interface.nic-k8s]
}

resource "azurerm_dns_a_record" "k8s" {
  name                = "k8s"
  zone_name           = data.azurerm_dns_zone.argentiacapital-com.name
  resource_group_name = data.azurerm_dns_zone.argentiacapital-com.resource_group_name
  ttl                 = 300

  # we may have to apply twice if use pip-k8s.
  #records  = [ azurerm_public_ip.pip-k8s.ip_address ]
  records    = [azurerm_linux_virtual_machine.vm-k8s.public_ip_address]
  depends_on = [azurerm_public_ip.pip-k8s]
}

resource "azurerm_dns_cname_record" "api" {
  name                = "api"
  zone_name           = data.azurerm_dns_zone.argentiacapital-com.name
  resource_group_name = data.azurerm_dns_zone.argentiacapital-com.resource_group_name
  ttl                 = 300

  record     = azurerm_kubernetes_cluster.aks.fqdn
  depends_on = [data.azurerm_dns_zone.argentiacapital-com]
}



resource "azurerm_dns_a_record" "demo" {
  name                = "demo"
  zone_name           = data.azurerm_dns_zone.argentiacapital-com.name
  resource_group_name = data.azurerm_dns_zone.argentiacapital-com.resource_group_name
  ttl                 = 300

  # IP would be only known after we provision the LB by k8s. so this step is done manually.
  records    = ["51.105.198.29"]
  depends_on = [data.azurerm_dns_zone.argentiacapital-com]
}

resource "azurerm_dns_a_record" "n1" {
  name                = "n1"
  zone_name           = data.azurerm_dns_zone.argentiacapital-com.name
  resource_group_name = data.azurerm_dns_zone.argentiacapital-com.resource_group_name
  ttl                 = 300

  # IP would be only known after we provision the LB by k8s. so this step is done manually.
  records    = ["20.160.159.195"]
  depends_on = [data.azurerm_dns_zone.argentiacapital-com]
}

resource "azurerm_dns_a_record" "ep" {
  name                = "ep"
  zone_name           = data.azurerm_dns_zone.argentiacapital-com.name
  resource_group_name = data.azurerm_dns_zone.argentiacapital-com.resource_group_name
  ttl                 = 300

  # IP would be only known after we provision the LB by k8s. so this step is done manually.
  records    = ["51.138.38.245"]
  depends_on = [data.azurerm_dns_zone.argentiacapital-com]
}


################### for windows VM & bastion
#------------------------------------------------------###################
# VNET & Subnets
#------------------------------------------------------###################

####################
# resource "azurerm_subnet" "winvm" {
#   name                 = var.subnet_name
#   resource_group_name  = azurerm_resource_group.challenge2-rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   address_prefixes     = ["10.0.0.0/24"]
# }

# resource "azurerm_subnet" "bastion" {
#   name                 = "AzureBastionSubnet"
#   resource_group_name  = azurerm_resource_group.challenge2-rg.name
#   virtual_network_name = azurerm_virtual_network.vnet.name
#   #address_prefixes     = ["10.0.1.0/27"]
#   address_prefixes     = ["10.0.2.0/24"]
# }


#------------------------------------------------------###################
# VM for BASTION
#------------------------------------------------------###################

# resource "azurerm_network_interface" "winvm" {
#   name                = var.network_interface_name
#   location            = var.location
#   resource_group_name = azurerm_resource_group.challenge2-rg.name

#   ip_configuration {
#     name                          = "myNicConfiguration"
#     subnet_id                     = azurerm_subnet.winvm.id
#     private_ip_address_allocation = "Dynamic"
#     # public_ip_address_id          = azurerm_public_ip.public_ip.id
#   }
# }

# resource "azurerm_windows_virtual_machine" "winvm" {
#   name                  = var.windows_vm_name
#   location              = var.location
#   resource_group_name   = azurerm_resource_group.challenge2-rg.name
#   network_interface_ids = [azurerm_network_interface.winvm.id]
#   size                  = "Standard_DS1_v2"
#   admin_username        = "azuser"
#   admin_password        = "adminFC9"

#   os_disk {
#     name                 = "winvmOsDisk"
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsDesktop"
#     offer     = "Windows-10"
#     sku       = "20h1-pro-g2"
#     version   = "latest"
#   }
# }


#------------------------------------------------------###################
# BASTION
#------------------------------------------------------###################

# resource "azurerm_public_ip" "bastion" {
#   name                = "bastionip"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.challenge2-rg.name
#   allocation_method   = "Static"
#   sku                 = "Standard"
# }

# resource "azurerm_bastion_host" "bastion" {
#   name                = "bastion"
#   location            = var.location
#   resource_group_name = azurerm_resource_group.challenge2-rg.name

#   ip_configuration {
#     name                 = "configuration"
#     subnet_id            = azurerm_subnet.bastion.id
#     public_ip_address_id = azurerm_public_ip.bastion.id
#   }
# }
#--------------------------------------------------------------------------
# Install tools in Bastion VM
#--------------------------------------------------------------------------

// resource "azurerm_virtual_machine_extension" "extension" {
//   name                 = "k8s-tools-deploy"
//   virtual_machine_id   = azurerm_windows_virtual_machine.winvm.id
//   publisher            = "Microsoft.Azure.Extensions"
//   type                 = "CustomScript"
//   type_handler_version = "1.9.5" # "2.0"

//   settings = <<SETTINGS
//     {
//         "script": "hostname"
//     }
// SETTINGS

// //   settings = <<SETTINGS
// //     {
// //         "script": "hostname"
// //         # "commandToExecute": "hostname"
// //     }
// // SETTINGS
// }

// resource "azurerm_virtual_machine_extension" "extension" {
//   name                 = "k8s-tools-deploy01"
//   virtual_machine_id   = azurerm_windows_virtual_machine.winvm.id
//   publisher            = "Microsoft.Compute"
//   type                 = "CustomScriptExtension"
//   type_handler_version = "1.9.5" # "2.0"

//   settings = <<SETTINGS
//     {
//         "script": "hostname"
//     }
// SETTINGS

// //   settings = <<SETTINGS
// //     {
// //         "script": "hostname"
// //         # "commandToExecute": "hostname"
// //     }
// // SETTINGS
// }

# # Install Azure CLI
# Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; rm .\AzureCLI.msi
#
# # Install chocolately
# Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
#
# # Install Kubernetes CLI
# choco install kubernetes-cli
#
# # Install Helm CLI
# choco install kubernetes-helm
