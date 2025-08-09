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
  # FortiWeb instances configuration
  nva_instances = var.hub_nva_high_availability ? [
    {
      name = "primary"
      zone = "1"
      private_ip = var.hub_nva_management_ip
      priority = 100
    },
    {
      name = "secondary" 
      zone = "2"
      private_ip = cidrhost(var.hub_virtual_network_address_prefix, tonumber(split(".", var.hub_nva_management_ip)[3]) + 1)
      priority = 90
    }
  ] : [
    {
      name = "primary"
      zone = null
      private_ip = var.hub_nva_management_ip
      priority = 100
    }
  ]

  # VIP configurations for load balancer
  vip_configs = [
    {
      name = "docs"
      port = 80
      private_ip = var.hub_nva_vip_docs
      enabled = var.application_docs
    },
    {
      name = "dvwa"
      port = 80
      private_ip = var.hub_nva_vip_dvwa
      enabled = var.application_dvwa
    },
    {
      name = "ollama"
      port = 80
      private_ip = var.hub_nva_vip_ollama
      enabled = var.application_ollama
    },
    {
      name = "video"
      port = 80
      private_ip = var.hub_nva_vip_video
      enabled = var.application_video
    },
    {
      name = "extractor"
      port = 80
      private_ip = var.hub_nva_vip_extractor
      enabled = var.application_extractor
    }
  ]
}

#===============================================================================
# Load Balancer Infrastructure
#===============================================================================

# Standard Load Balancer for high availability
resource "azurerm_lb" "hub_nva_lb" {
  count = var.hub_nva_high_availability ? 1 : 0

  name                = "hub-nva-lb"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  sku                 = "Standard"
  sku_tier           = "Regional"

  tags = local.standard_tags
}

# Load Balancer Backend Pool
resource "azurerm_lb_backend_address_pool" "hub_nva_backend_pool" {
  count = var.hub_nva_high_availability ? 1 : 0

  name            = "hub-nva-backend-pool"
  loadbalancer_id = azurerm_lb.hub_nva_lb[0].id
}

# Health Probe for FortiWeb instances
resource "azurerm_lb_probe" "hub_nva_health_probe" {
  count = var.hub_nva_high_availability ? 1 : 0

  name                = "hub-nva-health-probe"
  loadbalancer_id     = azurerm_lb.hub_nva_lb[0].id
  protocol            = "Http"
  port                = 8080  # FortiWeb admin/health port
  request_path        = "/healthcheck"
  interval_in_seconds = 30
  number_of_probes    = 3
}

#===============================================================================
# FortiWeb NVA Instances
#===============================================================================

# Network interfaces for each NVA instance
resource "azurerm_network_interface" "hub_nva_external_interfaces" {
  for_each = { for idx, instance in local.nva_instances : instance.name => instance }

  name                          = "hub-nva-${each.key}-external-nic"
  location                      = azurerm_resource_group.azure_resource_group.location
  resource_group_name           = azurerm_resource_group.azure_resource_group.name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "external-config"
    subnet_id                     = azurerm_subnet.hub_external_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = each.value.private_ip
    primary                       = true
    public_ip_address_id         = var.management_public_ip && each.key == "primary" ? azurerm_public_ip.hub_nva_management_public_ip[0].id : null
  }

  tags = local.standard_tags
}

resource "azurerm_network_interface" "hub_nva_internal_interfaces" {
  for_each = { for idx, instance in local.nva_instances : instance.name => instance }

  name                          = "hub-nva-${each.key}-internal-nic"
  location                      = azurerm_resource_group.azure_resource_group.location
  resource_group_name           = azurerm_resource_group.azure_resource_group.name
  accelerated_networking_enabled = true

  ip_configuration {
    name                          = "internal-config"
    subnet_id                     = azurerm_subnet.hub_internal_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = cidrhost(var.hub_internal_subnet_address_prefix, tonumber(split(".", each.value.private_ip)[3]))
  }

  tags = local.standard_tags
}

# Associate NICs with load balancer backend pool (HA mode only)
resource "azurerm_network_interface_backend_address_pool_association" "hub_nva_lb_association" {
  for_each = var.hub_nva_high_availability ? { for idx, instance in local.nva_instances : instance.name => instance } : {}

  network_interface_id    = azurerm_network_interface.hub_nva_external_interfaces[each.key].id
  ip_configuration_name   = "external-config"
  backend_address_pool_id = azurerm_lb_backend_address_pool.hub_nva_backend_pool[0].id
}

# FortiWeb Virtual Machines
resource "azurerm_linux_virtual_machine" "hub_nva_instances" {
  for_each = { for idx, instance in local.nva_instances : instance.name => instance }

  name                            = "hub-nva-${each.key}"
  resource_group_name             = azurerm_resource_group.azure_resource_group.name
  location                        = azurerm_resource_group.azure_resource_group.location
  size                            = var.production_environment ? "Standard_F4s_v2" : "Standard_F2s_v2"
  zone                           = each.value.zone
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

  custom_data = base64encode(templatefile("${path.module}/cloud-init/fortiweb-ha.conf", {
    var_admin_password                       = var.hub_nva_password
    var_api_user_password                    = var.hub_nva_password
    var_fqdn_management                      = var.management_public_ip ? azurerm_public_ip.hub_nva_management_public_ip[0].fqdn : ""
    var_dns_zone                            = var.dns_zone
    var_privatekey                          = tls_private_key.private_key.private_key_pem
    var_spoke_virtual_network_address_prefix = var.spoke_virtual_network_address_prefix
    var_instance_role                        = each.key
    var_cluster_priority                     = each.value.priority
    var_peer_ip                             = var.hub_nva_high_availability && each.key == "primary" ? local.nva_instances[1].private_ip : (var.hub_nva_high_availability ? local.nva_instances[0].private_ip : "")
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
resource "azurerm_lb_rule" "hub_nva_app_rules" {
  for_each = var.hub_nva_high_availability ? { for vip in local.vip_configs : vip.name => vip if vip.enabled } : {}

  name                           = "rule-${each.key}"
  loadbalancer_id               = azurerm_lb.hub_nva_lb[0].id
  protocol                      = "Tcp"
  frontend_port                 = each.value.port
  backend_port                  = each.value.port
  frontend_ip_configuration_name = "frontend-${each.key}"
  backend_address_pool_ids      = [azurerm_lb_backend_address_pool.hub_nva_backend_pool[0].id]
  probe_id                      = azurerm_lb_probe.hub_nva_health_probe[0].id
  enable_floating_ip            = false
  idle_timeout_in_minutes       = 4
  load_distribution             = "SourceIPProtocol"  # Session persistence
}

#===============================================================================
# Monitoring and Alerting
#===============================================================================

# Diagnostic settings for load balancer (HA mode only)
resource "azurerm_monitor_diagnostic_setting" "hub_nva_lb_diagnostics" {
  count = var.hub_nva_high_availability ? 1 : 0

  name                       = "hub-nva-lb-diagnostics"
  target_resource_id         = azurerm_lb.hub_nva_lb[0].id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "LoadBalancerAlertEvent"
  }

  enabled_log {
    category = "LoadBalancerProbeHealthStatus"
  }

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
    threshold        = 50  # Alert if less than 50% of backends are healthy
  }

  action {
    action_group_id = var.action_group_id
  }

  tags = local.standard_tags
}