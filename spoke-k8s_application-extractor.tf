data "azurerm_public_ip" "hub-nva-vip_extractor_public_ip" {
  count               = var.application_extractor ? 1 : 0
  name                = azurerm_public_ip.hub-nva-vip_extractor_public_ip[0].name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_dns_cname_record" "extractor" {
  count               = var.application_extractor ? 1 : 0
  name                = "extractor"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub-nva-vip_extractor_public_ip[0].fqdn
}

resource "azurerm_public_ip" "hub-nva-vip_extractor_public_ip" {
  count               = var.application_extractor ? 1 : 0
  name                = "hub-nva-vip_extractor_public_ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "extractor-${azurerm_resource_group.azure_resource_group.name}"
}

resource "kubernetes_namespace" "extractor" {
  count = var.application_extractor ? 1 : 0
  depends_on = [
    azurerm_kubernetes_cluster.kubernetes_cluster
  ]
  metadata {
    name = "extractor"
    labels = {
      name = "extractor"
    }
  }
}

resource "kubernetes_secret" "extractor_fortiweb_login_secret" {
  count = var.application_extractor ? 1 : 0
  metadata {
    name      = "fortiweb-login-secret"
    namespace = kubernetes_namespace.extractor[0].metadata[0].name
  }
  data = {
    username = var.hub_nva_username
    password = var.hub_nva_password
  }
  type = "Opaque"
}

locals {
  extractor_manifest_repo_fqdn = "https://github.com/${var.github_org}/${var.manifests_applications_repo_name}.git"
}

resource "azurerm_kubernetes_flux_configuration" "extractor" {
  count                             = var.application_extractor ? 1 : 0
  name                              = "extractor"
  cluster_id                        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  namespace                         = "cluster-config"
  scope                             = "cluster"
  continuous_reconciliation_enabled = true
  git_repository {
    url                      = local.extractor_manifest_repo_fqdn
    reference_type           = "branch"
    reference_value          = "main"
    sync_interval_in_seconds = 60
  }
  kustomizations {
    name                       = "extractor-dependencies"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./extractor-dependencies"
    sync_interval_in_seconds   = 60
  }
  kustomizations {
    name                       = "extractor"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./extractor"
    depends_on                 = ["extractor-dependencies"]
    sync_interval_in_seconds   = 60
  }
  depends_on = [
    azurerm_kubernetes_flux_configuration.infrastructure
  ]
}
