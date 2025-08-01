data "azurerm_public_ip" "hub_nva_vip_dvwa_public_ip" {
  count               = var.application_dvwa ? 1 : 0
  name                = azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_dns_cname_record" "dvwa" {
  count               = var.application_dvwa ? 1 : 0
  name                = "dvwa"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_dns_cname_record" "app1" {
  count               = var.application_dvwa ? 1 : 0
  name                = "app1"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_dns_cname_record" "app2" {
  count               = var.application_dvwa ? 1 : 0
  name                = "app2"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_dns_cname_record" "app3" {
  count               = var.application_dvwa ? 1 : 0
  name                = "app3"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_dns_cname_record" "app4" {
  count               = var.application_dvwa ? 1 : 0
  name                = "app4"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_dns_cname_record" "app5" {
  count               = var.application_dvwa ? 1 : 0
  name                = "app5"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_dns_cname_record" "app6" {
  count               = var.application_dvwa ? 1 : 0
  name                = "app6"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_dns_cname_record" "app7" {
  count               = var.application_dvwa ? 1 : 0
  name                = "app7"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_dvwa_public_ip[0].fqdn
}

resource "azurerm_public_ip" "hub_nva_vip_dvwa_public_ip" {
  count               = var.application_dvwa ? 1 : 0
  name                = "hub_nva_vip_dvwa_public_ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "dvwa-${azurerm_resource_group.azure_resource_group.name}"
}

resource "kubernetes_namespace" "dvwa" {
  count = var.application_dvwa ? 1 : 0
  depends_on = [
    azurerm_kubernetes_cluster.kubernetes_cluster
  ]
  metadata {
    name = "dvwa"
    labels = {
      name = "dvwa"
    }
  }
}

resource "kubernetes_secret" "dvwa_fortiweb_login_secret" {
  count = var.application_dvwa ? 1 : 0
  metadata {
    name      = "fortiweb-login-secret"
    namespace = kubernetes_namespace.dvwa[0].metadata[0].name
  }
  data = {
    username = var.hub_nva_username
    password = var.hub_nva_password
  }
  type = "Opaque"
}

locals {
  #dvwa_manifest_repo_fqdn = "git@github.com:${var.github_org}/${var.manifests_applications_repo_name}.git"
  dvwa_manifest_repo_fqdn = "https://github.com/${var.github_org}/${var.manifests_applications_repo_name}.git"
}

resource "azurerm_kubernetes_flux_configuration" "dvwa" {
  count                             = var.application_dvwa ? 1 : 0
  name                              = "dvwa"
  cluster_id                        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  namespace                         = "cluster-config"
  scope                             = "cluster"
  continuous_reconciliation_enabled = true
  git_repository {
    url                      = local.dvwa_manifest_repo_fqdn
    reference_type           = "branch"
    reference_value          = "main"
    sync_interval_in_seconds = 60
    #ssh_private_key_base64   = base64encode(var.manifests_applications_ssh_private_key)
  }
  kustomizations {
    name                       = "dvwa"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./dvwa"
    depends_on                 = ["dvwa-dependencies"]
    sync_interval_in_seconds   = 60
  }
  kustomizations {
    name                       = "dvwa-dependencies"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./dvwa-dependencies"
    sync_interval_in_seconds   = 60
  }
  depends_on = [
    azurerm_kubernetes_flux_configuration.infrastructure
  ]
}
