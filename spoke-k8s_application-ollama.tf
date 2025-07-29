data "azurerm_public_ip" "hub-nva-vip_ollama_public_ip" {
  count               = var.application_ollama ? 1 : 0
  name                = azurerm_public_ip.hub-nva-vip_ollama_public_ip[0].name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_dns_cname_record" "ollama" {
  count               = var.application_ollama ? 1 : 0
  name                = "ollama"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub-nva-vip_ollama_public_ip[0].fqdn
}

resource "azurerm_public_ip" "hub-nva-vip_ollama_public_ip" {
  count               = var.application_ollama ? 1 : 0
  name                = "hub-nva-vip_ollama_public_ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "ollama-${azurerm_resource_group.azure_resource_group.name}"
}

resource "kubernetes_namespace" "ollama" {
  count = var.application_ollama ? 1 : 0
  depends_on = [
    azurerm_kubernetes_cluster.kubernetes_cluster
  ]
  metadata {
    name = "ollama"
    labels = {
      name = "ollama"
    }
  }
}

resource "kubernetes_secret" "ollama_fortiweb_login_secret" {
  count = var.application_ollama ? 1 : 0
  metadata {
    name      = "fortiweb-login-secret"
    namespace = kubernetes_namespace.ollama[0].metadata[0].name
  }
  data = {
    username = var.hub_nva_username
    password = var.hub_nva_password
  }
  type = "Opaque"
}

locals {
  ollama_manifest_repo_fqdn = "git@github.com:${var.github_org}/${var.manifests_applications_repo_name}.git"
}

resource "azurerm_kubernetes_flux_configuration" "ollama" {
  count                             = var.application_ollama ? 1 : 0
  name                              = "ollama"
  cluster_id                        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  namespace                         = "cluster-config"
  scope                             = "cluster"
  continuous_reconciliation_enabled = true
  git_repository {
    url                      = local.ollama_manifest_repo_fqdn
    reference_type           = "branch"
    reference_value          = "ollama-version"
    sync_interval_in_seconds = 60
    ssh_private_key_base64   = base64encode(var.manifests_applications_ssh_private_key)
  }
  kustomizations {
    name                       = "ollama-dependencies"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./ollama-dependencies"
    sync_interval_in_seconds   = 60
  }
  kustomizations {
    name                       = "ollama"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./ollama"
    depends_on                 = ["ollama-dependencies"]
    sync_interval_in_seconds   = 60
  }
  #kustomizations {
  #  name                       = "ollama-post-deployment-config"
  #  recreating_enabled         = true
  #  garbage_collection_enabled = true
  #  path                       = "./ollama-post-deployment-config"
  #  depends_on                 = ["ollama"]
  #  sync_interval_in_seconds   = 60
  #}
  depends_on = [
    azurerm_kubernetes_flux_configuration.infrastructure
  ]
}

resource "null_resource" "trigger_ollama-version_workflow" {
  count = var.application_ollama ? 1 : 0
  provisioner "local-exec" {
    command = "gh workflow run ollama-version --repo ${var.github_org}/${var.manifests_applications_repo_name} --ref main"
  }
}
