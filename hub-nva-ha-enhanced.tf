#===============================================================================
# Hub Network Virtual Appliance (NVA) High Availability Configuration
#
# Enhanced version of hub-nva.tf with multi-zone deployment and load balancing
# Addresses critical single point of failure in the original architecture
#
# Key Improvements:
# - Multi-zone FortiWeb deployment (2 instances across zones)
# - Azure Standard Load Balancer for traffic distribution
# - Availability zones instead of availability sets
# - Health probes and automated failover
# - Simplified IP configuration with shared VIPs
#===============================================================================

# Variables for HA configuration
locals {
  # FortiWeb instances configuration - use different IP ranges for HA to avoid conflicts
  nva_instances = var.hub_nva_high_availability ? [
    {
      name       = "primary"
      zone       = "1"
      private_ip = "10.0.0.20" # Use different IP range to avoid conflicts with single instance
      priority   = 100
    },
    {
      name       = "secondary"
      zone       = "2"
      private_ip = "10.0.0.21" # Sequential IP for secondary instance
      priority   = 90
    }
    ] : [
    {
      name       = "primary"
      zone       = null
      private_ip = var.hub_nva_management_ip # Keep original for single instance
      priority   = 100
    }
  ]

  # VIP configurations for load balancer
  vip_configs = [
    {
      name       = "docs"
      port       = 80
      private_ip = var.hub_nva_vip_docs
      enabled    = var.application_docs
    },
    {
      name       = "dvwa"
      port       = 80
      private_ip = var.hub_nva_vip_dvwa
      enabled    = var.application_dvwa
    },
    {
      name       = "ollama"
      port       = 80
      private_ip = var.hub_nva_vip_ollama
      enabled    = var.application_ollama
    },
    {
      name       = "video"
      port       = 80
      private_ip = var.hub_nva_vip_video
      enabled    = var.application_video
    },
    {
      name       = "extractor"
      port       = 80
      private_ip = var.hub_nva_vip_extractor
      enabled    = var.application_extractor
    }
  ]
}

#===============================================================================
# Load Balancer Infrastructure
#===============================================================================

# Standard Load Balancer for high availability
resource "azurerm_lb" "hub_nva_lb" {
  count = var.hub_nva_high_availability ? 1 : 0

  # Ensure single-instance resources are destroyed first to avoid IP conflicts
  depends_on = [
    azurerm_network_interface.hub_nva_external_network_interface,
    azurerm_network_interface.hub_nva_internal_network_interface,
    azurerm_linux_virtual_machine.hub_nva_virtual_machine
  ]

  name                = "hub-nva-lb-${random_string.vm_suffix.result}"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  dynamic "frontend_ip_configuration" {
    for_each = { for vip in local.vip_configs : vip.name => vip if vip.enabled }
    content {
      name                          = "frontend-${frontend_ip_configuration.key}"
      subnet_id                     = azurerm_subnet.hub_external_subnet.id
      private_ip_address_allocation = "Static"
      private_ip_address            = frontend_ip_configuration.value.private_ip
    }
  }

  tags = local.standard_tags
}

# Load Balancer Backend Pool for each application
resource "azurerm_lb_backend_address_pool" "hub_nva_backend_pools" {
  for_each = var.hub_nva_high_availability ? { for vip in local.vip_configs : vip.name => vip if vip.enabled } : {}

  name            = "hub-nva-backend-pool-${each.key}-${random_string.vm_suffix.result}"
  loadbalancer_id = azurerm_lb.hub_nva_lb[0].id
}

# Health Probe for FortiWeb instances
resource "azurerm_lb_probe" "hub_nva_health_probe" {
  count = var.hub_nva_high_availability ? 1 : 0

  name                = "hub-nva-health-probe-${random_string.vm_suffix.result}"
  loadbalancer_id     = azurerm_lb.hub_nva_lb[0].id
  protocol            = "Http"
  port                = 8080 # FortiWeb admin/health port
  request_path        = "/healthcheck"
  interval_in_seconds = 30
  number_of_probes    = 3
}

#===============================================================================
# FortiWeb NVA Instances
#===============================================================================

# Public IPs for HA NVA instances management (separate from original single-instance management IP)
resource "azurerm_public_ip" "hub_nva_ha_management_public_ips" {
  for_each = var.hub_nva_high_availability && var.management_public_ip ? { for idx, instance in local.nva_instances : instance.name => instance } : {}

  name                = "hub-nva-ha-${each.key}-management-public-ip-${random_string.vm_suffix.result}"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "management-ha-${each.key}-${azurerm_resource_group.azure_resource_group.name}-${random_string.vm_suffix.result}"

  tags = merge(local.standard_tags, {
    Role = "FortiWeb-HA-Management-${each.key}"
  })
}

# Network interfaces for each NVA instance
resource "azurerm_network_interface" "hub_nva_external_interfaces" {
  for_each = var.hub_nva_high_availability ? { for idx, instance in local.nva_instances : instance.name => instance } : {}

  # Ensure single-instance resources are destroyed first to avoid IP conflicts
  depends_on = [
    azurerm_network_interface.hub_nva_external_network_interface,
    azurerm_network_interface.hub_nva_internal_network_interface,
    azurerm_linux_virtual_machine.hub_nva_virtual_machine
  ]

  name                           = "hub-nva-${each.key}-external-nic-${random_string.vm_suffix.result}"
  location                       = azurerm_resource_group.azure_resource_group.location
  resource_group_name            = azurerm_resource_group.azure_resource_group.name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "external-config"
    subnet_id                     = azurerm_subnet.hub_external_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
    primary                       = true
    public_ip_address_id          = var.management_public_ip ? azurerm_public_ip.hub_nva_ha_management_public_ips[each.key].id : null
  }

  tags = local.standard_tags
}

resource "azurerm_network_interface" "hub_nva_internal_interfaces" {
  for_each = var.hub_nva_high_availability ? { for idx, instance in local.nva_instances : instance.name => instance } : {}

  # Ensure single-instance resources are destroyed first to avoid IP conflicts
  depends_on = [
    azurerm_network_interface.hub_nva_external_network_interface,
    azurerm_network_interface.hub_nva_internal_network_interface,
    azurerm_linux_virtual_machine.hub_nva_virtual_machine
  ]

  name                = "hub-nva-${each.key}-internal-nic-${random_string.vm_suffix.result}"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  # Disable accelerated networking on internal NICs to avoid VM size restriction
  # Standard_F2s_v2 VMs can only have one NIC with accelerated networking
  accelerated_networking_enabled = false

  ip_configuration {
    name                          = "internal-config"
    subnet_id                     = azurerm_subnet.hub_internal_subnet.id
    private_ip_address_allocation = "Static"
    # For HA: primary=10.0.0.36, secondary=10.0.0.37 (within internal subnet range)
    private_ip_address = each.key == "primary" ? "10.0.0.36" : "10.0.0.37"
  }

  tags = local.standard_tags
}

# Associate NICs with load balancer backend pools (HA mode only)
# Each NIC needs to be associated with all backend pools since FortiWeb handles routing
resource "azurerm_network_interface_backend_address_pool_association" "hub_nva_lb_associations" {
  for_each = var.hub_nva_high_availability ? {
    for pair in setproduct(
      [for idx, instance in local.nva_instances : instance.name],
      [for vip in local.vip_configs : vip.name if vip.enabled]
      ) : "${pair[0]}-${pair[1]}" => {
      instance = pair[0]
      app      = pair[1]
    }
  } : {}

  network_interface_id    = azurerm_network_interface.hub_nva_external_interfaces[each.value.instance].id
  ip_configuration_name   = "external-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub_nva_backend_pools[each.value.app].id
}

# Random suffix to avoid name conflicts with orphaned VMs from failed deployments
resource "random_string" "vm_suffix" {
  length  = 6
  upper   = false
  special = false
  numeric = true
}

# FortiWeb Virtual Machines
resource "azurerm_linux_virtual_machine" "hub_nva_instances" {
  for_each = var.hub_nva_high_availability ? { for idx, instance in local.nva_instances : instance.name => instance } : {}

  name                            = "hub-nva-${each.key}-${random_string.vm_suffix.result}"
  resource_group_name             = azurerm_resource_group.azure_resource_group.name
  location                        = azurerm_resource_group.azure_resource_group.location
  size                            = var.production_environment ? "Standard_F4s_v2" : "Standard_F2s_v2"
  zone                            = each.value.zone
  disable_password_authentication = false #tfsec:ignore:AVD-AZU-0039

  # Enhanced identity for monitoring and management
  identity {
    type = "SystemAssigned"
  }

  network_interface_ids = [
    azurerm_network_interface.hub_nva_external_interfaces[each.key].id,
    azurerm_network_interface.hub_nva_internal_interfaces[each.key].id
  ]

  admin_username = var.hub_nva_admin_username
  admin_password = var.hub_nva_password

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = var.production_environment ? "Premium_LRS" : "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = local.vm_image.fortiweb.publisher
    offer     = local.vm_image.fortiweb.offer
    sku       = local.vm_image.fortiweb.sku
    version   = local.vm_image.fortiweb.version
  }

  plan {
    publisher = local.vm_image.fortiweb.publisher
    product   = local.vm_image.fortiweb.offer
    name      = local.vm_image.fortiweb.sku
  }

  # Temporarily use simpler cloud-init config to avoid provisioning timeouts
  # Switch back to HA config after basic deployment works
  custom_data = base64encode(templatefile("${path.module}/cloud-init/fortiweb.conf", {
    var_config_system_global_admin_sport     = local.vm_image.fortiweb.management-port
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
    var_hub_nva_username                     = var.hub_nva_admin_username
    var_certificate                          = tls_self_signed_cert.self_signed_cert.cert_pem
    var_privatekey                           = tls_private_key.private_key.private_key_pem
    var_fwb_license_file                     = ""
    var_fwb_license_fortiflex                = ""
    var_spoke_aks_network                    = var.spoke_aks_subnet_prefix
  }))

  tags = merge(local.standard_tags, {
    Role = "FortiWeb-${each.key}"
    Zone = each.value.zone != null ? each.value.zone : "single"
  })
}

#===============================================================================
# Load Balancer Rules and VIP Configuration
#===============================================================================

# Load balancer rules for each enabled application (HA mode only)
# Each application gets its own backend pool to avoid conflicts
resource "azurerm_lb_rule" "hub_nva_app_rules" {
  for_each = var.hub_nva_high_availability ? { for vip in local.vip_configs : vip.name => vip if vip.enabled } : {}

  name                           = "rule-${each.key}-${random_string.vm_suffix.result}"
  loadbalancer_id                = azurerm_lb.hub_nva_lb[0].id
  protocol                       = "Tcp"
  frontend_port                  = each.value.port
  backend_port                   = each.value.port
  frontend_ip_configuration_name = "frontend-${each.key}"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.hub_nva_backend_pools[each.key].id]
  probe_id                       = azurerm_lb_probe.hub_nva_health_probe[0].id
  enable_floating_ip             = true # Required for FortiWeb VIP handling
  idle_timeout_in_minutes        = 4
  load_distribution              = "SourceIPProtocol" # Session persistence
}

#===============================================================================
# Monitoring and Alerting
#===============================================================================

# Diagnostic settings for load balancer (HA mode only)
resource "azurerm_monitor_diagnostic_setting" "hub_nva_lb_diagnostics" {
  count = var.hub_nva_high_availability ? 1 : 0

  name                       = "hub-nva-lb-diagnostics"
  target_resource_id         = azurerm_lb.hub_nva_lb[0].id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform_workspace.id

  # Note: Azure Load Balancer does not support log categories, only metrics
  # LoadBalancerAlertEvent and LoadBalancerProbeHealthStatus are not supported

  enabled_metric {
    category = "AllMetrics"
  }
}

# Alert rules for NVA health monitoring
resource "azurerm_monitor_metric_alert" "hub_nva_health_alert" {
  count = var.hub_nva_high_availability ? 1 : 0

  name                = "hub-nva-health-alert"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [azurerm_lb.hub_nva_lb[0].id]
  description         = "Alert when FortiWeb NVA instances are unhealthy"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/loadBalancers"
    metric_name      = "DipAvailability"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 50 # Alert if less than 50% of backends are healthy
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical_alerts.id
  }

  tags = local.standard_tags
}