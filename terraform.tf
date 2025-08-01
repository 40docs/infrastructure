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
  required_version = ">= 1.6"

  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.5"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.38"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "~> 1.6"
    }
    github = {
      source  = "integrations/github"
      version = "~> 6.6"
    }
    htpasswd = {
      source  = "loafoe/htpasswd"
      version = "~> 1.2"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.1"
    }
  }

  # Backend configuration for remote state management
  # Configuration is provided via backend-config parameters in GitHub Actions
  backend "azurerm" {
    # Values are provided via -backend-config parameters in GitHub Actions:
    # - storage_account_name
    # - container_name  
    # - key
    # - resource_group_name
  }
}
