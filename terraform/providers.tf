provider "azurerm" {
  subscription_id = var.subscription_id

  features {
    virtual_machine {
      delete_os_disk_on_deletion = var.vm_delete_os_disk_on_deletion
    }
  }
}
