#===============================================================================
# Enhanced Monitoring and Observability Configuration
#
# Comprehensive monitoring solution for the 40docs platform including:
# - Log Analytics Workspace with custom queries
# - Application Insights for application monitoring
# - Azure Monitor alerts and action groups
# - Custom dashboards and workbooks
# - Network monitoring and flow logs
#===============================================================================

# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "platform_workspace" {
  name                = "${var.project_name}-logs-${var.environment}"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  sku                 = var.production_environment ? "PerGB2018" : "PerGB2018"
  retention_in_days   = var.production_environment ? 90 : 30

  daily_quota_gb = var.production_environment ? 50 : 0.5

  tags = local.standard_tags
}

# Application Insights for application monitoring
resource "azurerm_application_insights" "platform_insights" {
  name                = "${var.project_name}-insights-${var.environment}"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  workspace_id        = azurerm_log_analytics_workspace.platform_workspace.id
  application_type    = "web"

  tags = local.standard_tags
}

#===============================================================================
# Action Groups for Alerting
#===============================================================================

# Critical alerts action group (SMS, email, webhook)
resource "azurerm_monitor_action_group" "critical_alerts" {
  name                = "critical-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  short_name          = "critical"

  email_receiver {
    name          = "admin-email"
    email_address = var.owner_email
  }

  dynamic "webhook_receiver" {
    for_each = toset(length(var.teams_webhook_url) > 0 ? [var.teams_webhook_url] : [])
    content {
      name        = "teams-webhook"
      service_uri = webhook_receiver.value
    }
  }

  tags = local.standard_tags
}

# Warning alerts action group (email only)
resource "azurerm_monitor_action_group" "warning_alerts" {
  name                = "warning-alerts-${var.environment}"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  short_name          = "warning"

  email_receiver {
    name          = "admin-email"
    email_address = var.owner_email
  }

  tags = local.standard_tags
}

#===============================================================================
# FortiWeb NVA Monitoring
#===============================================================================

# FortiWeb CPU utilization alert
resource "azurerm_monitor_metric_alert" "fortiweb_cpu_alert" {
  for_each = var.hub_nva_high_availability ? toset(["primary", "secondary"]) : toset(["primary"])

  name                = "fortiweb-${each.key}-cpu-alert"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [var.hub_nva_high_availability ? azurerm_linux_virtual_machine.hub_nva_instances[each.key].id : azurerm_linux_virtual_machine.hub_nva_virtual_machine[0].id]
  description         = "Alert when FortiWeb ${each.key} CPU utilization exceeds threshold"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 85
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning_alerts.id
  }

  tags = local.standard_tags
}

# FortiWeb memory utilization alert
resource "azurerm_monitor_metric_alert" "fortiweb_memory_alert" {
  for_each = var.hub_nva_high_availability ? toset(["primary", "secondary"]) : toset(["primary"])

  name                = "fortiweb-${each.key}-memory-alert"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [var.hub_nva_high_availability ? azurerm_linux_virtual_machine.hub_nva_instances[each.key].id : azurerm_linux_virtual_machine.hub_nva_virtual_machine[0].id]
  description         = "Alert when FortiWeb ${each.key} available memory is low"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Available Memory Bytes"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 536870912 # 512 MB
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning_alerts.id
  }

  tags = local.standard_tags
}

#===============================================================================
# AKS Cluster Monitoring
#===============================================================================

# AKS node CPU alert
resource "azurerm_monitor_metric_alert" "aks_node_cpu_alert" {
  name                = "aks-node-cpu-alert"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [azurerm_kubernetes_cluster.kubernetes_cluster.id]
  description         = "Alert when AKS node CPU utilization is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "node_cpu_usage_percentage"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning_alerts.id
  }

  tags = local.standard_tags
}

# AKS pod restart alert
resource "azurerm_monitor_metric_alert" "aks_pod_restart_alert" {
  name                = "aks-pod-restart-alert"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [azurerm_kubernetes_cluster.kubernetes_cluster.id]
  description         = "Alert when pods are restarting frequently"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT15M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.ContainerService/managedClusters"
    metric_name      = "kube_pod_status_phase"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5

    dimension {
      name     = "phase"
      operator = "Include"
      values   = ["Failed"]
    }
  }

  action {
    action_group_id = azurerm_monitor_action_group.critical_alerts.id
  }

  tags = local.standard_tags
}

#===============================================================================
# Application-Specific Monitoring
#===============================================================================

# HTTP response time alert for applications
resource "azurerm_monitor_metric_alert" "app_response_time_alert" {
  for_each = {
    for app, enabled in {
      docs      = var.application_docs
      dvwa      = var.application_dvwa
      ollama    = var.application_ollama
      extractor = var.application_extractor
    } : app => app if enabled
  }

  name                = "${each.key}-response-time-alert"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  scopes              = [azurerm_application_insights.platform_insights.id]
  description         = "Alert when ${each.key} application response time is high"
  severity            = 2
  frequency           = "PT1M"
  window_size         = "PT5M"
  enabled             = true

  criteria {
    metric_namespace = "Microsoft.Insights/components"
    metric_name      = "requests/duration"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5000 # 5 seconds

    # Note: Removing dimension filter as request/name is not a valid dimension for requests/duration
    # Application Insights will aggregate across all requests for the application
    # For more granular filtering, would need to use Log Analytics queries instead
  }

  action {
    action_group_id = azurerm_monitor_action_group.warning_alerts.id
  }

  tags = local.standard_tags
}

#===============================================================================
# Network Security Group Flow Logs
#===============================================================================

# Storage account for NSG flow logs
resource "azurerm_storage_account" "nsg_flow_logs" {
  name                     = "${replace(var.project_name, "-", "")}nsgflow${var.environment}"
  resource_group_name      = azurerm_resource_group.azure_resource_group.name
  location                 = azurerm_resource_group.azure_resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  min_tls_version          = "TLS1_2"

  blob_properties {
    delete_retention_policy {
      days = var.production_environment ? 30 : 7
    }
  }

  tags = local.standard_tags
}

# Network Watcher data source - use existing Network Watcher (Azure creates one by default per region)
data "azurerm_network_watcher" "network_watcher" {
  name                = "NetworkWatcher_${azurerm_resource_group.azure_resource_group.location}"
  resource_group_name = "NetworkWatcherRG" # Default resource group created by Azure
}

# Network Watcher Flow Logs for hub NSG
resource "azurerm_network_watcher_flow_log" "hub_nsg_flow_log" {
  network_watcher_name = data.azurerm_network_watcher.network_watcher.name
  resource_group_name  = data.azurerm_network_watcher.network_watcher.resource_group_name
  name                 = "hub-nsg-flow-log"

  network_security_group_id = azurerm_network_security_group.hub_external_network_security_group.id
  storage_account_id        = azurerm_storage_account.nsg_flow_logs.id
  enabled                   = true

  retention_policy {
    enabled = true
    days    = var.production_environment ? 30 : 7
  }

  traffic_analytics {
    enabled               = true
    workspace_id          = azurerm_log_analytics_workspace.platform_workspace.workspace_id
    workspace_region      = azurerm_log_analytics_workspace.platform_workspace.location
    workspace_resource_id = azurerm_log_analytics_workspace.platform_workspace.id
    interval_in_minutes   = 10
  }

  tags = local.standard_tags
}

#===============================================================================
# Custom Log Analytics Queries and Saved Searches
#===============================================================================

# FortiWeb performance query
resource "azurerm_log_analytics_saved_search" "fortiweb_performance" {
  name                       = "FortiWebPerformance"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform_workspace.id
  category                   = "Security"
  display_name               = "FortiWeb Performance Metrics"

  query = <<-EOT
    Perf
    | where Computer contains "hub-nva"
    | where CounterName in ("% Processor Time", "Available MBytes", "Bytes Total/sec")
    | summarize avg(CounterValue) by Computer, CounterName, bin(TimeGenerated, 5m)
    | render timechart
  EOT

  lifecycle {
    ignore_changes = [
      # Ignore changes if this resource already exists
      name,
      query
    ]
  }

  tags = local.standard_tags
}

# Application error analysis query
resource "azurerm_log_analytics_saved_search" "app_error_analysis" {
  name                       = "ApplicationErrorAnalysis"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform_workspace.id
  category                   = "Application"
  display_name               = "Application Error Analysis"

  query = <<-EOT
    AppExceptions
    | where TimeGenerated > ago(24h)
    | summarize count() by ProblemId, AppRoleName
    | order by count_ desc
    | limit 20
  EOT

  lifecycle {
    ignore_changes = [
      # Ignore changes if this resource already exists
      name,
      query
    ]
  }

  tags = local.standard_tags
}

# Network traffic analysis query
resource "azurerm_log_analytics_saved_search" "network_traffic_analysis" {
  name                       = "NetworkTrafficAnalysis"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform_workspace.id
  category                   = "Network"
  display_name               = "Network Traffic Analysis"

  query = <<-EOT
    AzureNetworkAnalytics_CL
    | where TimeGenerated > ago(1h)
    | where FlowType_s == "ExternalPublic"
    | summarize count() by SrcIP_s, DestIP_s, DestPort_d
    | order by count_ desc
    | limit 50
  EOT

  lifecycle {
    ignore_changes = [
      # Ignore changes if this resource already exists
      name,
      query
    ]
  }

  tags = local.standard_tags
}

#===============================================================================
# Monitoring Dashboard
#===============================================================================

# Create monitoring dashboard - COMMENTED OUT: Missing template file
# resource "azurerm_portal_dashboard" "platform_dashboard" {
#   name                = "${var.project_name}-monitoring-dashboard"
#   resource_group_name = azurerm_resource_group.azure_resource_group.name
#   location            = azurerm_resource_group.azure_resource_group.location
#
#   dashboard_properties = templatefile("${path.module}/templates/monitoring-dashboard.json", {
#     subscription_id         = data.azurerm_client_config.current.subscription_id
#     resource_group_name    = azurerm_resource_group.azure_resource_group.name
#     workspace_id           = azurerm_log_analytics_workspace.platform_workspace.id
#     application_insights_id = azurerm_application_insights.platform_insights.id
#     aks_cluster_id         = azurerm_kubernetes_cluster.kubernetes_cluster.id
#   })
#
#   tags = local.standard_tags
# }
