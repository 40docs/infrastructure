data "azurerm_public_ip" "hub_nva_vip_docs_public_ip" {
  count               = var.application_docs ? 1 : 0
  name                = azurerm_public_ip.hub_nva_vip_docs_public_ip[0].name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
}

resource "azurerm_dns_cname_record" "docs" {
  count               = var.application_docs ? 1 : 0
  name                = "docs"
  zone_name           = azurerm_dns_zone.dns_zone.name
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  ttl                 = 300
  record              = data.azurerm_public_ip.hub_nva_vip_docs_public_ip[0].fqdn
}

resource "azurerm_public_ip" "hub_nva_vip_docs_public_ip" {
  count               = var.application_docs ? 1 : 0
  name                = "hub-nva-vip_docs_public_ip"
  location            = azurerm_resource_group.azure_resource_group.location
  resource_group_name = azurerm_resource_group.azure_resource_group.name
  allocation_method   = "Static"
  sku                 = "Standard"
  domain_name_label   = "docs-${azurerm_resource_group.azure_resource_group.name}"
}

resource "kubernetes_namespace" "docs" {
  count = var.application_docs ? 1 : 0
  depends_on = [
    azurerm_kubernetes_cluster.kubernetes_cluster
  ]
  metadata {
    name = "docs"
    labels = {
      name = "docs"
    }
  }
}

resource "random_password" "salt" {
  length  = 8
  special = false
  #override_special = "!@#%&*()-_=+[]{}<>:?"
}

resource "htpasswd_password" "hash" {
  password = var.htpasswd
}

resource "kubernetes_secret" "htpasswd_secret" {
  count = var.application_docs ? 1 : 0
  metadata {
    name      = "htpasswd-secret"
    namespace = kubernetes_namespace.docs[0].metadata[0].name
  }
  data = {
    htpasswd = "${var.htusername}:${htpasswd_password.hash.apr1}"
  }
  type = "Opaque"
}

resource "kubernetes_secret" "docs_fortiweb_login_secret" {
  count = var.application_docs ? 1 : 0
  metadata {
    name      = "fortiweb-login-secret"
    namespace = kubernetes_namespace.docs[0].metadata[0].name
  }
  data = {
    username = var.hub_nva_username
    password = var.hub_nva_password
  }
  type = "Opaque"
}

locals {
  docs_manifest_repo_fqdn = "https://github.com/${var.github_org}/${var.manifests_applications_repo_name}.git"
}

resource "azurerm_kubernetes_flux_configuration" "docs" {
  count                             = var.application_docs ? 1 : 0
  name                              = "docs"
  cluster_id                        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  namespace                         = "cluster-config"
  scope                             = "cluster"
  continuous_reconciliation_enabled = true
  git_repository {
    url                      = local.docs_manifest_repo_fqdn
    reference_type           = "branch"
    reference_value          = "docs-version"
    sync_interval_in_seconds = 60
  }
  kustomizations {
    name                       = "docs-dependencies"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./docs-dependencies"
    sync_interval_in_seconds   = 60
  }
  kustomizations {
    name                       = "docs"
    recreating_enabled         = true
    garbage_collection_enabled = true
    path                       = "./docs"
    depends_on                 = ["docs-dependencies"]
    sync_interval_in_seconds   = 60
  }
  #kustomizations {
  #  name                       = "docs-post-deployment-config"
  #  recreating_enabled         = true
  #  garbage_collection_enabled = true
  #  path                       = "./docs-post-deployment-config"
  #  depends_on                 = ["docs"]
  #  sync_interval_in_seconds   = 60
  #}
  depends_on = [
    azurerm_kubernetes_flux_configuration.infrastructure
  ]
}

resource "github_actions_secret" "DOCS_BUILDER_ACR_LOGIN_SERVER" {
  count           = var.application_docs ? 1 : 0
  repository      = var.docs_builder_repo_name
  secret_name     = "ACR_LOGIN_SERVER"
  plaintext_value = azurerm_container_registry.container_registry.login_server
}

resource "github_actions_secret" "MANIFESTS_APPLICATIONS_ACR_LOGIN_SERVER" {
  count           = var.application_docs ? 1 : 0
  repository      = var.manifests_applications_repo_name
  secret_name     = "ACR_LOGIN_SERVER"
  plaintext_value = azurerm_container_registry.container_registry.login_server
}

resource "null_resource" "trigger_docs_builder_workflow" {
  count = var.application_docs ? 1 : 0
  depends_on = [
    github_actions_secret.DOCS_BUILDER_ACR_LOGIN_SERVER
  ]
  triggers = {
    acr_login_server = azurerm_container_registry.container_registry.login_server
  }
  provisioner "local-exec" {
    command = "gh workflow run docs-builder --repo ${var.github_org}/${var.docs_builder_repo_name} --ref main"
  }
}

