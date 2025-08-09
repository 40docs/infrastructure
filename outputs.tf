###############################################################
# Output Values
#
# This file defines output values that are useful for other
# configurations or for displaying information after deployment.
###############################################################

# Resource Group Information
output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.azure_resource_group.name
}

output "resource_group_location" {
  description = "Location of the created resource group"
  value       = azurerm_resource_group.azure_resource_group.location
}

# Network Information
output "hub_virtual_network_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub_virtual_network.id
}

output "spoke_virtual_network_id" {
  description = "ID of the spoke virtual network"
  value       = azurerm_virtual_network.spoke_virtual_network.id
}

# Kubernetes Cluster Information
output "kubernetes_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.kubernetes_cluster.name
}

output "kubernetes_cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.kubernetes_cluster.fqdn
}

output "kube_config" {
  description = "Kubernetes cluster configuration"
  value       = azurerm_kubernetes_cluster.kubernetes_cluster.kube_config_raw
  sensitive   = true
}

# DNS Zone Information
output "dns_zone_name" {
  description = "Name of the DNS zone"
  value       = azurerm_dns_zone.dns_zone.name
}

output "dns_zone_name_servers" {
  description = "Name servers for the DNS zone"
  value       = azurerm_dns_zone.dns_zone.name_servers
}

# NVA Management Access
output "hub_nva_management_public_ip" {
  description = "Public IP address for NVA management (if enabled)"
  value = var.management_public_ip ? (
    var.hub_nva_high_availability ? {
      for k, v in azurerm_public_ip.hub_nva_ha_management_public_ips : k => v.ip_address
    } : {
      single = azurerm_public_ip.hub_nva_management_public_ip[0].ip_address
    }
  ) : null
}

output "hub_nva_management_fqdn" {
  description = "FQDN for NVA management access (if enabled)"
  value = var.management_public_ip ? (
    var.hub_nva_high_availability ? {
      for k, v in azurerm_public_ip.hub_nva_ha_management_public_ips : k => v.fqdn
    } : {
      single = azurerm_public_ip.hub_nva_management_public_ip[0].fqdn
    }
  ) : null
}
