locals {
  rg_tags = merge(var.common_tags, {
    name = var.resource_group_name
  })
  vm_image = var.vm_images[var.vm_os_family]
}
