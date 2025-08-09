#===============================================================================
# Hub Network Virtual Appliance (NVA) Configuration
#
# This file configures the FortiWeb NVA instances in the hub network.
# Includes public IPs, DNS records, availability sets, and network interfaces.
#
# Resources:
# - Public IPs for management and VIP access
# - DNS CNAME records for domain management
# - Availability set for high availability
# - Network interfaces for external and internal connectivity
# - Virtual machine instance running FortiWeb
#===============================================================================

# Public IP for NVA management access (single instance only)
resource "azurerm_public_ip" "hub_nva_management_public_ip" {
  count = !var.hub_nva_high_availability && var.management_public_ip ? 1 : 0

  name                = "hub-nva-management-public-ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "management-${azurerm_resource_group.azure_resource_group.name}"

  tags = local.standard_tags
}

# DNS CNAME record for NVA management (single instance only)
resource "azurerm_dns_cname_record" "hub_nva" {
  count = !var.hub_nva_high_availability && var.management_public_ip ? 1 : 0

  name                = "hub-nva"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_management_public_ip[0].fqdn

  tags = local.standard_tags
}

# Availability set for NVA (single instance only)
resource "azurerm_availability_set" "hub_nva_availability_set" {
  count = !var.hub_nva_high_availability ? 1 : 0

  name                         = "hub-nva-availability-set"
  location                     = azurerm_resource_group.azure_resource_group.location
  resource_group_name          = azurerm_resource_group.azure_resource_group.name
  platform_fault_domain_count  = 2
  platform_update_domain_count = 2

  tags = local.standard_tags
}

locals {
  ip_configurations = [
    {
      name                          = "hub-nva-external-management_ip_configuration"
      primary                       = true
      private_ip_address_allocation = "Static"
      private_ip_address            = var.hub_nva_management_ip
      subnet_id                     = azurerm_subnet.hub_external_subnet.id
      public_ip_address_id          = var.management_public_ip ? (length(azurerm_public_ip.hub_nva_management_public_ip) > 0 ? azurerm_public_ip.hub_nva_management_public_ip[0].id : null) : null
      condition                     = true
    },
    {
      name                          = "hub-nva-external-vip-docs_configuration"
      primary                       = false
      private_ip_address_allocation = "Static"
      private_ip_address            = var.hub_nva_vip_docs
      subnet_id                     = azurerm_subnet.hub_external_subnet.id
      public_ip_address_id          = length(azurerm_public_ip.hub_nva_vip_docs_public_ip) > 0 ? azurerm_public_ip.hub_nva_vip_docs_public_ip[0].id : null
      condition                     = var.application_docs
    },
    {
      name                          = "hub-nva-external-vip-dvwa_configuration"
      primary                       = false
      private_ip_address_allocation = "Static"
      private_ip_address            = var.hub_nva_vip_dvwa
      subnet_id                     = azurerm_subnet.hub_external_subnet.id
      public_ip_address_id          = length(azurerm_public_ip.hub_nva_vip_dvwa_public_ip) > 0 ? azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].id : null
      condition                     = var.application_dvwa
    },
    {
      name                          = "hub-nva-external-vip-ollama_configuration"
      primary                       = false
      private_ip_address_allocation = "Static"
      private_ip_address            = var.hub_nva_vip_ollama
      subnet_id                     = azurerm_subnet.hub_external_subnet.id
      public_ip_address_id          = length(azurerm_public_ip.hub_nva_vip_ollama_public_ip) > 0 ? azurerm_public_ip.hub_nva_vip_ollama_public_ip[0].id : null
      condition                     = var.application_ollama
    },
    {
      name                          = "hub-nva-external-vip-video_configuration"
      primary                       = false
      private_ip_address_allocation = "Static"
      private_ip_address            = var.hub_nva_vip_video
      subnet_id                     = azurerm_subnet.hub_external_subnet.id
      public_ip_address_id          = length(azurerm_public_ip.hub_nva_vip_video_public_ip) > 0 ? azurerm_public_ip.hub_nva_vip_video_public_ip[0].id : null
      condition                     = var.application_video
    },
    {
      name                          = "hub-nva-external-vip-extractor_configuration"
      primary                       = false
      private_ip_address_allocation = "Static"
      private_ip_address            = var.hub_nva_vip_extractor
      subnet_id                     = azurerm_subnet.hub_external_subnet.id
      public_ip_address_id          = length(azurerm_public_ip.hub_nva_vip_extractor_public_ip) > 0 ? azurerm_public_ip.hub_nva_vip_extractor_public_ip[0].id : null
      condition                     = var.application_extractor
    }
  ]
}

# External network interface for hub NVA (single instance only)
resource "azurerm_network_interface" "hub_nva_external_network_interface" {
  count = !var.hub_nva_high_availability ? 1 : 0

  name                           = "hub-nva-external_network_interface"
  location                       = azurerm_resource_group.azure_resource_group.location
  resource_group_name            = azurerm_resource_group.azure_resource_group.name
  accelerated_networking_enabled = true

  dynamic "ip_configuration" {
    # Only include IP configurations when NOT in HA mode
    for_each = !var.hub_nva_high_availability ? [for ip in local.ip_configurations : ip if ip.condition] : []

    content {
      name                          = ip_configuration.value.name
      primary                       = lookup(ip_configuration.value, "primary", false)
      private_ip_address_allocation = ip_configuration.value.private_ip_address_allocation
      private_ip_address            = ip_configuration.value.private_ip_address
      subnet_id                     = ip_configuration.value.subnet_id
      public_ip_address_id          = ip_configuration.value.public_ip_address_id
    }
  }

  tags = local.standard_tags
}

# Internal network interface for hub NVA (single instance only)
resource "azurerm_network_interface" "hub_nva_internal_network_interface" {
  count = !var.hub_nva_high_availability ? 1 : 0

  name                           = "hub-nva-internal_network_interface"
  location                       = azurerm_resource_group.azure_resource_group.location
  resource_group_name            = azurerm_resource_group.azure_resource_group.name
  accelerated_networking_enabled = true
  ip_forwarding_enabled          = true #checkov:skip=CKV_AZURE_118:Fortigate NIC needs IP forwarding.

  ip_configuration {
    name                          = "hub-nva-internal_ip_configuration"
    private_ip_address_allocation = "Static"
    # Use a dedicated IP for single instance to avoid conflict with HA secondary (10.0.0.37)
    private_ip_address = "10.0.0.35" # Different IP than HA secondary (10.0.0.37)
    subnet_id          = azurerm_subnet.hub_internal_subnet.id
  }

  tags = local.standard_tags
}

# Linux Virtual Machine running FortiWeb NVA (single instance only)
resource "azurerm_linux_virtual_machine" "hub_nva_virtual_machine" {
  count = !var.hub_nva_high_availability ? 1 : 0

  #checkov:skip=CKV_AZURE_178: Allow Fortigate to present HTTPS login UI instead of SSH
  #checkov:skip=CKV_AZURE_149: Allow Fortigate to present HTTPS login UI instead of SSH
  #checkov:skip=CKV_AZURE_1: Allow Fortigate to present HTTPS login UI instead of SSH
  #depends_on                      = [null_resource.marketplace_agreement, azurerm_managed_disk.log_disk]
  depends_on                      = [null_resource.marketplace_agreement]
  name                            = "hub-nva_virtual_machine"
  computer_name                   = "hub-nva"
  availability_set_id             = azurerm_availability_set.hub_nva_availability_set[0].id
  admin_username                  = var.hub_nva_username
  disable_password_authentication = false #tfsec:ignore:AVD-AZU-0039
  admin_password                  = var.hub_nva_password
  location                        = azurerm_resource_group.azure_resource_group.location
  resource_group_name             = azurerm_resource_group.azure_resource_group.name
  network_interface_ids           = [azurerm_network_interface.hub_nva_external_network_interface[0].id, azurerm_network_interface.hub_nva_internal_network_interface[0].id]
  size                            = var.production_environment ? local.vm_image[var.hub_nva_image].size : local.vm_image[var.hub_nva_image].size-dev
  allow_extension_operations      = false

  identity {
    type = "SystemAssigned"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.production_environment ? "Premium_LRS" : "Standard_LRS"
    #disk_size_gb = var.production_environment ? 256 : 128
  }
  plan {
    name      = local.vm_image[var.hub_nva_image].sku
    product   = local.vm_image[var.hub_nva_image].offer
    publisher = local.vm_image[var.hub_nva_image].publisher
  }
  source_image_reference {
    offer     = local.vm_image[var.hub_nva_image].offer
    publisher = local.vm_image[var.hub_nva_image].publisher
    sku       = local.vm_image[var.hub_nva_image].sku
    version   = "latest"
  }
  custom_data = base64encode(
    templatefile("cloud-init/${var.hub_nva_image}.conf",
      {
        var_config_system_global_admin_sport     = local.vm_image[var.hub_nva_image].management-port
        var_hub_external_subnet_gateway          = var.hub_external_subnet_gateway
        var_spoke_check_internet_up_ip           = var.spoke_check_internet_up_ip
        var_spoke_default_gateway                = cidrhost(var.hub_internal_subnet_prefix, 1)
        var_spoke_virtual_network_address_prefix = var.spoke_virtual_network_address_prefix
        var_spoke_virtual_network_subnet         = cidrhost(var.spoke_virtual_network_address_prefix, 0)
        var_spoke_virtual_network_netmask        = cidrnetmask(var.spoke_virtual_network_address_prefix)
        var_spoke_aks_node_ip                    = var.spoke_aks_node_ip
        var_hub_nva_vip_docs                     = var.hub_nva_vip_docs
        var_hub_nva_vip_ollama                   = var.hub_nva_vip_ollama
        var_hub_nva_vip_video                    = var.hub_nva_vip_video
        var_hub_nva_vip_dvwa                     = var.hub_nva_vip_dvwa
        var_hub_nva_vip_artifacts                = var.hub_nva_vip_artifacts
        var_hub_nva_vip_extractor                = var.hub_nva_vip_extractor
        var_hub_nva_username                     = var.hub_nva_username
        var_certificate                          = tls_self_signed_cert.self_signed_cert.cert_pem
        var_privatekey                           = tls_private_key.private_key.private_key_pem
        var_fwb_license_file                     = ""
        var_fwb_license_fortiflex                = ""
        var_spoke_aks_network                    = var.spoke_aks_subnet_prefix
      }
    )
  )
}
