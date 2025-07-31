###############################################################
# Terraform Root Configuration
#
# This file defines provider requirements, backend, and global
# settings for the infrastructure. Follows best practices for
# versioning, backend, and provider configuration.
#
# See .github/instructions/terraform.instructions.md for details.
###############################################################

terraform {
  required_version = ">=1.6"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "4.38.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
    }
    azapi = {
      source  = "azure/azapi"
      version = "2.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38.0"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "1.2.1"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.6.4"
    }
  }
  # Recommended: configure remote backend for state management
  backend "azurerm" {
    # storage_account_name = "<your_storage_account>"
    # container_name       = "tfstate"
    # key                  = "infrastructure.terraform.tfstate"
    # resource_group_name  = "<your_resource_group>"
  }
}

###############################################################
# Standard resource tags for traceability and cost management
###############################################################
locals {
  standard_tags = {
    Project     = var.project_name
    Owner       = var.name
    OwnerEmail  = var.owner_email
    Environment = var.production_environment ? "production" : "non-production"
  }
}

data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {
}

provider "azurerm" {
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
