#===============================================================================
# Azure Kubernetes Service (AKS) Cluster Configuration
#
# This file contains the AKS cluster and supporting infrastructure including
# container registry, log analytics, and monitoring configuration.
#
# Resources:
# - Container Registry for storing container images
# - Log Analytics workspace for monitoring
# - AKS cluster with node pools and networking
# - Data collection rules for monitoring
#===============================================================================

#===============================================================================
# Container Registry
#===============================================================================

# Generate random name for container registry (must be globally unique)
resource "random_string" "acr_name" {
  length  = 25
  upper   = false
  special = false
  numeric = false
}

# Azure Container Registry for storing container images
resource "azurerm_container_registry" "container_registry" {
  name                          = random_string.acr_name.result
  resource_group_name           = azurerm_resource_group.azure_resource_group.name
  location                      = azurerm_resource_group.azure_resource_group.location
  sku                           = var.production_environment ? "Standard" : "Basic"
  admin_enabled                 = false
  public_network_access_enabled = true
  anonymous_pull_enabled        = false
  tags                          = local.standard_tags
}

#===============================================================================
# Monitoring Infrastructure
#===============================================================================

# Log Analytics workspace for AKS monitoring
resource "azurerm_log_analytics_workspace" "log_analytics" {
  name                = "log-analytics"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.standard_tags
}

#===============================================================================
# Identity and RBAC Configuration
#===============================================================================

# User-assigned identity for AKS cluster
resource "azurerm_user_assigned_identity" "my_identity" {
  name                = "UserAssignedIdentity"
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  location            = azurerm_resource_group.azure_resource_group.location
  tags                = local.standard_tags
}

# Contributor role assignment for cluster identity
resource "azurerm_role_assignment" "kubernetes_contributor" {
  principal_id         = azurerm_user_assigned_identity.my_identity.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_resource_group.azure_resource_group.id
}

# Network contributor role for route table management
resource "azurerm_role_assignment" "route_table_network_contributor" {
  principal_id                     = azurerm_user_assigned_identity.my_identity.principal_id
  role_definition_name             = "Network Contributor"
  scope                            = azurerm_resource_group.azure_resource_group.id
  skip_service_principal_aad_check = true
}

# ACR pull role assignment for kubelet identity
resource "azurerm_role_assignment" "acr_role_assignment" {
  principal_id                     = azurerm_kubernetes_cluster.kubernetes_cluster.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.container_registry.id
  skip_service_principal_aad_check = true
}

#===============================================================================
# AKS Cluster Configuration
#===============================================================================

# Local values for cluster naming
locals {
  cluster_name        = substr("${azurerm_resource_group.azure_resource_group.name}_k8s-cluster_${var.location}", 0, 63)
  node_resource_group = substr("${azurerm_resource_group.azure_resource_group.name}_k8s-cluster_${var.location}_MC", 0, 80)
}

# Azure Kubernetes Service cluster
resource "azurerm_kubernetes_cluster" "kubernetes_cluster" {
  depends_on = [
    azurerm_virtual_network_peering.spoke_to_hub_virtual_network_peering,
    azurerm_linux_virtual_machine.hub_nva_virtual_machine,
    azurerm_linux_virtual_machine.hub_nva_instances
  ]
  name                              = local.cluster_name
  location                          = azurerm_resource_group.azure_resource_group.location
  resource_group_name               = azurerm_resource_group.azure_resource_group.name
  dns_prefix                        = azurerm_resource_group.azure_resource_group.name
  sku_tier                          = var.production_environment ? "Standard" : "Free"
  cost_analysis_enabled             = var.production_environment ? true : false
  support_plan                      = "KubernetesOfficial"
  kubernetes_version                = "1.31.10"
  node_resource_group               = local.node_resource_group
  role_based_access_control_enabled = true
  oidc_issuer_enabled               = true
  workload_identity_enabled         = true
  # OMS agent for monitoring integration
  oms_agent {
    log_analytics_workspace_id      = azurerm_log_analytics_workspace.log_analytics.id
    msi_auth_for_monitoring_enabled = true
  }
  # Azure Policy Add-on for governance
  azure_policy_enabled = var.production_environment ? true : false
  # Default node pool configuration
  default_node_pool {
    temporary_name_for_rotation  = "rotation"
    name                         = "system"
    auto_scaling_enabled         = var.production_environment
    node_count                   = var.production_environment ? 3 : 1
    min_count                    = var.production_environment ? 3 : null
    max_count                    = var.production_environment ? 7 : null
    vm_size                      = var.production_environment ? local.vm_image["aks"].size : local.vm_image["aks"].size-dev
    os_sku                       = "AzureLinux"
    max_pods                     = "75"
    orchestrator_version         = "1.31.10"
    vnet_subnet_id               = azurerm_subnet.spoke_subnet.id
    only_critical_addons_enabled = var.production_environment
    os_disk_type                 = "Managed"
    os_disk_size_gb              = 128
    upgrade_settings {
      max_surge = var.production_environment ? 10 : 1
    }
    node_labels = {
      "system-pool" = "true"
      "user-pool"   = var.production_environment ? false : true
    }
  }
  # Network profile configuration
  network_profile {
    network_plugin    = "kubenet"
    network_policy    = "calico"
    load_balancer_sku = "standard"
    pod_cidr          = var.spoke_aks_pod_cidr
  }
  # Restrict API server to CloudShell public IP and GitHub Actions when CloudShell is enabled
  #dynamic "api_server_access_profile" {
  #  for_each = var.cloudshell ? [1] : []
  #  content {
  #    authorized_ip_ranges = concat(
  #     ["${azurerm_public_ip.cloudshell_public_ip[0].ip_address}/32"],
  #      [
  #        # GitHub Actions IP ranges - major blocks
  #        "4.0.0.0/8",        # GitHub Actions primary range
  #        "20.0.0.0/8",       # Additional GitHub Actions range
  #        "52.0.0.0/8",       # Azure/GitHub Actions range
  #        "140.82.112.0/20",  # GitHub.com range
  #        "143.55.64.0/20",   # GitHub Actions range
  #        "185.199.108.0/22", # GitHub Pages/Actions
  #       "192.30.252.0/22"   # GitHub API range
  #      ]
  #    )
  #  }
  #}
  # System-assigned managed identity
  identity {
    type = "SystemAssigned"
  }
  tags = local.standard_tags
}

resource "azurerm_kubernetes_cluster_node_pool" "cpu_node_pool" {
  count                 = var.production_environment ? 1 : 0
  name                  = "cpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.kubernetes_cluster.id
  vm_size               = var.production_environment ? local.vm_image["aks"].cpu-size : local.vm_image["aks"].cpu-size-dev
  os_sku                = "AzureLinux"
  auto_scaling_enabled  = var.production_environment
  min_count             = var.production_environment ? 3 : null
  max_count             = var.production_environment ? 5 : null
  node_count            = var.production_environment ? 3 : 1
  os_disk_type          = var.production_environment ? "Managed" : "Ephemeral"
  ultra_ssd_enabled     = var.production_environment ? null : true
  os_disk_size_gb       = var.production_environment ? "256" : "175"
  max_pods              = "50"
  zones                 = ["1"]
  vnet_subnet_id        = azurerm_subnet.spoke_subnet.id
}

resource "azurerm_kubernetes_cluster_node_pool" "gpu_node_pool" {
  count                 = var.gpu_node_pool ? 1 : 0
  name                  = "gpu"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.kubernetes_cluster.id
  vm_size               = var.production_environment ? local.vm_image["aks"].gpu-size : local.vm_image["aks"].gpu-size-dev
  os_sku                = "AzureLinux"
  auto_scaling_enabled  = var.production_environment
  min_count             = var.production_environment ? 3 : null
  max_count             = var.production_environment ? 5 : null
  node_count            = var.production_environment ? 3 : 1
  node_taints           = ["nvidia.com/gpu=true:NoSchedule"]
  node_labels = {
    "nvidia.com/gpu.present" = "true"
  }
  os_disk_type      = var.production_environment ? "Managed" : "Ephemeral"
  ultra_ssd_enabled = var.production_environment ? null : true
  os_disk_size_gb   = var.production_environment ? "256" : "175"
  max_pods          = "50"
  zones             = ["1"]
  vnet_subnet_id    = azurerm_subnet.spoke_subnet.id
}

resource "azurerm_kubernetes_cluster_extension" "flux_extension" {
  name              = "flux-extension"
  cluster_id        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  extension_type    = "microsoft.flux"
  release_namespace = "flux-system"
  depends_on        = [azurerm_kubernetes_cluster.kubernetes_cluster]
  configuration_settings = {
    "image-automation-controller.enabled" = true,
    "image-reflector-controller.enabled"  = true,
    "helm-controller.detectDrift"         = true,
    "notification-controller.enabled"     = true
  }
}
