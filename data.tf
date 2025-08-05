###############################################################
# Data Sources
#
# This file contains all data source definitions for gathering
# information about existing Azure resources and configuration.
###############################################################

data "azurerm_public_ip" "hub_nva_management_public_ip" {
  count               = var.management_public_ip ? 1 : 0
  name                = azurerm_public_ip.hub_nva_management_public_ip[0].name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

data "azurerm_public_ip" "cloudshell_public_ip" {
  count               = var.cloudshell ? 1 : 0
  name                = azurerm_public_ip.cloudshell_public_ip[count.index].name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}
