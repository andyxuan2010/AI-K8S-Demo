output "resource_group_name" {
  value = module.resource_group.name
}

# k8s jumpbox
output "pip-k8s" {
  value = azurerm_public_ip.pip-k8s.ip_address
}

output "hostname-k8s" {
  value = var.dns_zone.enabled ? azurerm_dns_a_record.k8s[0].fqdn : null
}

#node pip created by itself
output "aks-node1-ip" {
  value = var.dns_zone.enabled ? tolist(azurerm_dns_a_record.n1[0].records)[0] : null
}

#LB pip created by ingress-nginx-controller
output "aks-demo" {
  value = var.dns_zone.enabled ? tolist(azurerm_dns_a_record.demo[0].records)[0] : null
}

output "aks_ep" {
  value = var.dns_zone.enabled ? tolist(azurerm_dns_a_record.ep[0].records)[0] : null
}

output "aks_fqdn" {
  value = module.aks.fqdn
}


output "aks_node_rg" {
  value = module.aks.node_resource_group
}

# output "acr_login_server" {
#   value = azurerm_container_registry.basfacr.login_server
# }



