#===============================================================================
# Hub Network Infrastructure
#
# This file contains the core networking infrastructure for the hub network,
# including DNS zone, virtual network, subnets, and network peering to spoke.
#
# Resources:
# - DNS Zone for domain management
# - Hub Virtual Network with external and internal subnets
# - Virtual Network Peering from hub to spoke
#===============================================================================

# DNS Zone for domain management
resource "azurerm_dns_zone" "dns_zone" {
  name                = var.dns_zone
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  tags                = local.standard_tags
}

# Hub Virtual Network - Central networking component
resource "azurerm_virtual_network" "hub_virtual_network" {
  name                = "hub_virtual_network"
  address_space       = [var.hub_virtual_network_address_prefix]
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  tags                = local.standard_tags
}

# Virtual Network Peering from Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke_virtual_network_peering" {
  name                      = "hub-to-spoke_virtual_network_peering"
  resource_group_name       = azurerm_resource_group.azure_resource_group.name
  virtual_network_name      = azurerm_virtual_network.hub_virtual_network.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_virtual_network.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
  depends_on = [
    azurerm_virtual_network.hub_virtual_network,
    azurerm_virtual_network.spoke_virtual_network
  ]
}

#===============================================================================
# Hub Subnets
#===============================================================================

# External subnet for internet-facing resources
resource "azurerm_subnet" "hub_external_subnet" {
  name                 = var.hub_external_subnet_name
  address_prefixes     = [var.hub_external_subnet_prefix]
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.hub_virtual_network.name
}

# Internal subnet for internal resources
resource "azurerm_subnet" "hub_internal_subnet" {
  name                 = var.hub_internal_subnet_name
  address_prefixes     = [var.hub_internal_subnet_prefix]
  resource_group_name  = azurerm_resource_group.azure_resource_group.name
  virtual_network_name = azurerm_virtual_network.hub_virtual_network.name
}

#===============================================================================
# Hub Network Routing
#===============================================================================

# Route table for hub network traffic
resource "azurerm_route_table" "hub_route_table" {
  name                = "hub_route_table"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  route {
    name           = "default"
    address_prefix = "0.0.0.0/0"
    next_hop_type  = "Internet"
  }
  tags = local.standard_tags
}

# Associate route table with internal subnet
resource "azurerm_subnet_route_table_association" "hub_internal_route_table_association" {
  subnet_id      = azurerm_subnet.hub_internal_subnet.id
  route_table_id = azurerm_route_table.hub_route_table.id
}

# Associate route table with external subnet
resource "azurerm_subnet_route_table_association" "hub_external_route_table_association" {
  subnet_id      = azurerm_subnet.hub_external_subnet.id
  route_table_id = azurerm_route_table.hub_route_table.id
}

#===============================================================================
# Hub Network Security Groups
#===============================================================================

# Network Security Group for External Subnet
# Controls internet-facing traffic and NVA management access
resource "azurerm_network_security_group" "hub_external_network_security_group" { #tfsec:ignore:azure-network-no-public-ingress
  name                = "hub-external_network_security_group"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name

  # Management access rule for NVA (restricted to management network)
  security_rule {
    name                       = "MGMT_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = local.vm_image[var.hub_nva_image].management-port
    source_address_prefix      = "Internet"
    destination_address_prefix = var.hub_nva_management_ip
  }

  # Virtual IP rule for docs application (public access required)
  security_rule {
    name                       = "VIP_rule-docs"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"] #checkov:skip=CKV_AZURE_160: Allow HTTP redirects
    source_address_prefix      = "Internet"
    destination_address_prefix = var.hub_nva_vip_docs
  }

  # Virtual IP rule for DVWA application
  security_rule {
    name                       = "VIP_rule-dvwa"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"] #checkov:skip=CKV_AZURE_160: Allow HTTP redirects
    source_address_prefix      = "Internet"
    destination_address_prefix = var.hub_nva_vip_dvwa
  }

  # Virtual IP rule for Ollama application
  security_rule {
    name                       = "VIP_rule-ollama"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"] #checkov:skip=CKV_AZURE_160: Allow HTTP redirects
    source_address_prefix      = "Internet"
    destination_address_prefix = var.hub_nva_vip_ollama
  }

  # Virtual IP rule for video application
  security_rule {
    name                       = "VIP_rule-video"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"] #checkov:skip=CKV_AZURE_160: Allow HTTP redirects
    source_address_prefix      = "Internet"
    destination_address_prefix = var.hub_nva_vip_video
  }

  # Virtual IP rule for extractor application
  security_rule {
    name                       = "VIP_rule-extractor"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"] #checkov:skip=CKV_AZURE_160: Allow HTTP redirects
    source_address_prefix      = "Internet"
    destination_address_prefix = var.hub_nva_vip_extractor
  }
  tags = local.standard_tags
}

# Associate external NSG with external subnet
resource "azurerm_subnet_network_security_group_association" "hub_external_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.hub_external_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_external_network_security_group.id
}
# Network Security Group for Internal Subnet
# Controls internal traffic and communication with spoke networks
resource "azurerm_network_security_group" "hub_internal_network_security_group" {
  name                = "hub-internal_network_security_group"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  # Allow AKS node internet access for updates and container pulls
  security_rule {
    name                       = "aks-node_to_internet_rule"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "10.0.0.0/8"
    destination_address_prefix = "*"
  }

  # Allow ICMP for connectivity testing (restricted sources and destinations)
  security_rule {
    name                         = "icmp_to_dns_rule"
    priority                     = 101
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "Icmp"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "10.0.0.0/16"
    destination_address_prefixes = ["8.8.8.8/32", "8.8.4.4/32", "1.1.1.1/32"]
  }

  # Allow outbound HTTP traffic for applications (restricted to internal sources)
  security_rule {
    name                       = "outbound-http_rule"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8000", "8080", "11434"]
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "Internet"
  }
  tags = local.standard_tags
}

# Associate internal NSG with internal subnet
resource "azurerm_subnet_network_security_group_association" "hub_internal_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.hub_internal_subnet.id
  network_security_group_id = azurerm_network_security_group.hub_internal_network_security_group.id
}
