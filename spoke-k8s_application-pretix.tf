data "azurerm_public_ip" "hub_nva_vip_pretix_public_ip" {
  count               = var.application_signup ? 1 : 0
  name                = azurerm_public_ip.hub_nva_vip_pretix_public_ip[0].name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_dns_cname_record" "pretix" {
  count               = var.application_signup ? 1 : 0
  name                = "pretix"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_pretix_public_ip[0].fqdn
}

resource "azurerm_public_ip" "hub_nva_vip_pretix_public_ip" {
  count               = var.application_signup ? 1 : 0
  name                = "hub_nva_vip_pretix_public_ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "pretix-${azurerm_resource_group.azure_resource_group.name}"
}

resource "kubernetes_namespace" "pretix" {
  count = var.application_signup ? 1 : 0
  depends_on = [
    azurerm_kubernetes_cluster.kubernetes_cluster
  ]
  metadata {
    name = "pretix"
    labels = {
      name = "pretix"
    }
  }
}

resource "kubernetes_secret" "pretix_fortiweb_login_secret" {
  count = var.application_signup ? 1 : 0
  metadata {
    name      = "fortiweb-login-secret"
    namespace = kubernetes_namespace.pretix[0].metadata[0].name
  }
  data = {
    username = var.hub_nva_username
    password = var.hub_nva_password
  }
  type = "Opaque"
}

locals {
  pretix_manifest_repo_fqdn = "git@github.com:${var.github_org}/${var.manifests_applications_repo_name}.git"
}

resource "azurerm_kubernetes_flux_configuration" "pretix" {
  count                             = var.application_signup ? 1 : 0
  name                              = "pretix"
  cluster_id                        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  namespace                         = "cluster-config"
  scope                             = "cluster"
  continuous_reconciliation_enabled = true
  git_repository {
    url                      = local.pretix_manifest_repo_fqdn
    reference_type           = "branch"
    reference_value          = "pretix-version"
    sync_interval_in_seconds = 60
    ssh_private_key_base64   = base64encode(var.manifests_applications_ssh_private_key)
  }
  kustomizations {
    name                       = "pretix-dependencies"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./pretix-dependencies"
    sync_interval_in_seconds   = 60
  }
  kustomizations {
    name                       = "pretix"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./pretix"
    depends_on                 = ["pretix-dependencies"]
    sync_interval_in_seconds   = 60
  }
  #kustomizations {
  #  name                       = "pretix-post-deployment-config"
  #  recreating_enabled         = true
  #  garbage_collection_enabled = true
  #  path                       = "./pretix-post-deployment-config"
  #  depends_on                 = ["pretix"]
  #  sync_interval_in_seconds   = 60
  #}
  depends_on = [
    azurerm_kubernetes_flux_configuration.infrastructure
  ]
}
