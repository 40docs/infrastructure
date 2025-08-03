###############################################################
# Provider Configurations
#
# This file contains all provider configurations for the
# infrastructure. Separates provider config from version
# requirements for better organization.
###############################################################

provider "azurerm" {
  # Use the new resource_provider_registrations instead of deprecated skip_provider_registration
  resource_provider_registrations = "all"

  features {
    api_management {
      purge_soft_delete_on_destroy = true
      recover_soft_deleted         = false
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "random" {}

provider "tls" {}

provider "http" {}

provider "htpasswd" {}

provider "local" {}

provider "github" {
  owner = var.github_org
  token = var.github_token
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].cluster_ca_certificate)
}

provider "flux" {
  kubernetes = {
    host                   = azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.kubernetes_cluster.kube_config[0].cluster_ca_certificate)
  }
}
