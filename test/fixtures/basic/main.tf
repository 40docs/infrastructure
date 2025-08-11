# Test fixture for basic infrastructure validation
# This creates a minimal version of the infrastructure for testing

terraform {
  required_version = "~> 1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

# Resource Group
resource "azurerm_resource_group" "test" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Test"
    Purpose     = "Terratest"
    Owner       = var.owner_email
  }
}

# Hub VNet (simplified)
resource "azurerm_virtual_network" "hub" {
  name                = "${var.resource_group_name}-hub-vnet"
  address_space       = var.hub_vnet_address_space
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  tags = {
    Environment = "Test"
    Purpose     = "Terratest"
  }
}

# Hub External Subnet
resource "azurerm_subnet" "hub_external" {
  name                 = "external-subnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.hub_external_subnet]
}

# Spoke VNet (simplified)
resource "azurerm_virtual_network" "spoke" {
  name                = "${var.resource_group_name}-spoke-vnet"
  address_space       = var.spoke_vnet_address_space
  location            = azurerm_resource_group.test.location
  resource_group_name = azurerm_resource_group.test.name

  tags = {
    Environment = "Test"
    Purpose     = "Terratest"
  }
}

# Spoke AKS Subnet
resource "azurerm_subnet" "spoke_aks" {
  name                 = "aks-subnet"
  resource_group_name  = azurerm_resource_group.test.name
  virtual_network_name = azurerm_virtual_network.spoke.name
  address_prefixes     = [var.spoke_aks_subnet]
}

# VNet Peering Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "hub-to-spoke"
  resource_group_name       = azurerm_resource_group.test.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke.id
  allow_forwarded_traffic   = true
}

# VNet Peering Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "spoke-to-hub"
  resource_group_name       = azurerm_resource_group.test.name
  virtual_network_name      = azurerm_virtual_network.spoke.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}