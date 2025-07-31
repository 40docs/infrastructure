#===============================================================================
# Spoke Network Infrastructure
#
# This file contains the networking infrastructure for the spoke network,
# including virtual network, subnets, routing, and peering back to hub.
#
# Resources:
# - Spoke Virtual Network with regular and AKS subnets
# - Virtual Network Peering from spoke to hub
# - Route table directing traffic through NVA
# - Network security group for spoke resources
#===============================================================================

# Spoke Virtual Network - Contains AKS and application resources
resource "azurerm_virtual_network" "spoke_virtual_network" {
  name                = "spoke_virtual_network"
  address_space       = [var.spoke-virtual-network_address_prefix]
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  tags = local.standard_tags
}

# Virtual Network Peering from Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub_virtual_network_peering" {
  name                      = "spoke-to-hub_virtual_network_peering"
  resource_group_name       = azurerm_resource_group.azure_resource_group.name
  virtual_network_name      = azurerm_virtual_network.spoke_virtual_network.name
  remote_virtual_network_id = azurerm_virtual_network.hub_virtual_network.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true

  depends_on = [
    azurerm_virtual_network.hub_virtual_network,
    azurerm_virtual_network.spoke_virtual_network
  ]
}

#===============================================================================
# Spoke Subnets
#===============================================================================

# General purpose subnet for spoke resources
resource "azurerm_subnet" "spoke_subnet" {
  name                 = var.spoke-subnet_name
  address_prefixes     = [var.spoke-subnet_prefix]
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.spoke_virtual_network.name
}

# Dedicated subnet for AKS cluster
resource "azurerm_subnet" "spoke_aks_subnet" {
  name                 = var.spoke-aks-subnet_name
  address_prefixes     = [var.spoke-aks-subnet_prefix]
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.spoke_virtual_network.name
}

#===============================================================================
# Spoke Network Routing
#===============================================================================

# Route table directing spoke traffic through hub NVA
resource "azurerm_route_table" "spoke_route_table" {
  name                = "spoke_route_table"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.hub-nva-gateway
  }

  tags = local.standard_tags
}

# Associate route table with AKS subnet
resource "azurerm_subnet_route_table_association" "spoke_route_table_association" {
  subnet_id      = azurerm_subnet.spoke_aks_subnet.id
  route_table_id = azurerm_route_table.spoke_route_table.id
}

#===============================================================================
# Spoke Network Security
#===============================================================================

# Network Security Group for Spoke subnet
# Controls traffic for spoke resources and AKS communication
resource "azurerm_network_security_group" "spoke_network_security_group" {
  name                = "spoke_network_security_group"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  # Allow inbound HTTP traffic for applications
  security_rule { #tfsec:ignore:AVD-AZU-0047
    name                       = "inbound-http_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow AKS nodes to access internet for updates
  security_rule {
    name                       = "aks-node_to_internet_rule"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "*"
    destination_address_prefix = "*" #tfsec:ignore:AVD-AZU-0051
  }

  # Allow ICMP for connectivity testing
  security_rule { #tfsec:ignore:AVD-AZU-0051
    name                       = "icmp_to_google-dns_rule"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = local.standard_tags
}

# Associate NSG with spoke subnet
resource "azurerm_subnet_network_security_group_association" "spoke_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.spoke_subnet.id
  network_security_group_id = azurerm_network_security_group.spoke_network_security_group.id
}
