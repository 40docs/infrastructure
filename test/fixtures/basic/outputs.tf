output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.test.name
}

output "location" {
  description = "Azure location"
  value       = azurerm_resource_group.test.location
}

output "hub_vnet_name" {
  description = "Name of the hub VNet"
  value       = azurerm_virtual_network.hub.name
}

output "hub_vnet_id" {
  description = "ID of the hub VNet"
  value       = azurerm_virtual_network.hub.id
}

output "spoke_vnet_name" {
  description = "Name of the spoke VNet"
  value       = azurerm_virtual_network.spoke.name
}

output "spoke_vnet_id" {
  description = "ID of the spoke VNet"
  value       = azurerm_virtual_network.spoke.id
}

output "hub_external_subnet_id" {
  description = "ID of the hub external subnet"
  value       = azurerm_subnet.hub_external.id
}

output "spoke_aks_subnet_id" {
  description = "ID of the spoke AKS subnet"
  value       = azurerm_subnet.spoke_aks.id
}
