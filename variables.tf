###############################################################
# Terraform Variables
#
# This file defines all input variables for the infrastructure.
# Variables are organized alphabetically and follow naming conventions.
# All variables include type and description as per best practices.
#
# See .github/instructions/terraform.instructions.md for details.
###############################################################

# Application Configuration
variable "application_artifacts" {
  type        = bool
  description = "Deploy Artifacts application"
  default     = true
}

variable "application_docs" {
  type        = bool
  description = "Deploy Docs application"
  default     = true
}

variable "application_dvwa" {
  type        = bool
  description = "Deploy DVWA (Damn Vulnerable Web Application)"
  default     = true
}

variable "application_extractor" {
  type        = bool
  description = "Deploy Extractor application"
  default     = true
}

variable "application_ollama" {
  type        = bool
  description = "Deploy Ollama application"
  default     = true
}

variable "application_signup" {
  type        = bool
  description = "Deploy Signup application"
  default     = false
}

variable "application_video" {
  type        = bool
  description = "Deploy Video application"
  default     = true
}

# Azure Configuration
variable "arm_subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

# CloudShell Configuration
variable "cloudshell" {
  type        = bool
  description = "Deploy CloudShell VM"
  default     = false
}

# DNS Configuration
variable "dns_zone" {
  type        = string
  description = "DNS Zone for the deployment"
  default     = "example.com"
}

# GitHub Configuration
variable "docs_builder_repo_name" {
  type        = string
  description = "Name of the docs builder repository"
  default     = "docs-builder"
}

variable "github_org" {
  type        = string
  description = "GitHub organization name"
}

variable "github_token" {
  type        = string
  description = "GitHub token for authenticating to the repository"
  sensitive   = true
}

# HTTP Authentication
variable "htpasswd" {
  type        = string
  description = "Password for HTTP authentication"
  sensitive   = true
}

variable "htusername" {
  type        = string
  description = "Username for HTTP authentication"
}

# Hub NVA Configuration
variable "hub_nva_password" {
  type        = string
  description = "Password for Hub NVA device"
  sensitive   = true
}

variable "hub_nva_username" {
  type        = string
  description = "Username for Hub NVA device"
  sensitive   = true
}

# Let's Encrypt Configuration
variable "letsencrypt_url" {
  type        = string
  description = "Production or staging Let's Encrypt URL"

  validation {
    condition = contains([
      "https://acme-staging-v02.api.letsencrypt.org/directory",
      "https://acme-v02.api.letsencrypt.org/directory"
    ], var.letsencrypt_url)
    error_message = "letsencrypt_url must be either staging or production Let's Encrypt directory URL."
  }
}

# Project Configuration
variable "project_name" {
  type        = string
  description = "Project name for tagging and resource naming"
}

variable "location" {
  type        = string
  description = "Azure region for resource deployment"
  default     = "eastus"

  validation {
    condition = contains([
      "australiacentral", "australiacentral2", "australiaeast", "australiasoutheast",
      "brazilsouth", "brazilsoutheast", "canadacentral", "canadaeast",
      "centralindia", "centralus", "centraluseuap", "eastasia", "eastus", "eastus2",
      "eastus2euap", "francecentral", "francesouth", "germanynorth", "germanywestcentral",
      "israelcentral", "italynorth", "japaneast", "japanwest", "jioindiacentral",
      "jioindiawest", "koreacentral", "koreasouth", "mexicocentral", "northcentralus",
      "northeurope", "norwayeast", "norwaywest", "polandcentral", "qatarcentral",
      "southafricanorth", "southafricawest", "southcentralus", "southeastasia",
      "southindia", "swedencentral", "switzerlandnorth", "switzerlandwest",
      "uaecentral", "uaenorth", "uksouth", "ukwest", "westcentralus",
      "westeurope", "westindia", "westus", "westus2"
    ], var.location)
    error_message = "The location must be a valid Azure region."
  }
}

variable "production_environment" {
  type        = bool
  description = "Whether this is a production environment (affects resource sizing and configuration)"
  default     = true
}

# Lacework Configuration
variable "lw_agent_token" {
  type        = string
  description = "Lacework agent token for security monitoring"
  sensitive   = true
}

# Manifest Repository Configuration
variable "manifests_applications_repo_name" {
  type        = string
  description = "Name of the applications manifest repository"
}

variable "manifests_applications_ssh_private_key" {
  type        = string
  description = "SSH private key for applications manifest repository authentication"
  sensitive   = true
}

variable "manifests_infrastructure_repo_name" {
  type        = string
  description = "Name of the infrastructure manifest repository"
}

variable "manifests_infrastructure_ssh_private_key" {
  type        = string
  description = "SSH private key for infrastructure manifest repository authentication"
  sensitive   = true
}

# Environment Configuration
variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev, staging, prod)"
  default     = "dev"
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

# Management Configuration
variable "management_public_ip" {
  type        = bool
  description = "Whether to create a public IP for management access. Set to true in production via tfvars or CI/CD."
  default     = false
}

# Owner Information
variable "name" {
  type        = string
  description = "Full name of the owner for resource tagging"
}

variable "owner_email" {
  type        = string
  description = "Email address for use with Owner tag"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.owner_email))
    error_message = "The owner_email must be a valid email address."
  }
}

# Network Configuration - Hub
variable "hub_virtual_network_address_prefix" {
  type        = string
  description = "Hub Virtual Network Address prefix"
  default     = "10.0.0.0/24"

  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.hub_virtual_network_address_prefix))
    error_message = "The subnet must be in the format of 'xxx.xxx.xxx.xxx/xx', where xxx is between 0 and 255, and xx is between 0 and 32."
  }
}

variable "hub_internal_subnet_name" {
  default     = "hub-internal_subnet"
  description = "Hub Subnet Name."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]*$", var.hub_internal_subnet_name))
    error_message = "The value must consist of alphanumeric characters, underscores, or dashes only."
  }
}

variable "hub_internal_subnet_prefix" {
  default     = "10.0.0.32/27"
  description = "Hub Subnet Prefix."
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.hub_internal_subnet_prefix))
    error_message = "The subnet must be in the format of 'xxx.xxx.xxx.xxx/xx', where xxx is between 0 and 255, and xx is between 0 and 32."
  }
}

variable "hub_external_subnet_name" {
  default     = "hub-external_subnet"
  description = "External Subnet Name."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]*$", var.hub_external_subnet_name))
    error_message = "The value must consist of alphanumeric characters, underscores, or dashes only."
  }
}

variable "hub_external_subnet_prefix" {
  default     = "10.0.0.0/27"
  description = "External Subnet Prefix."
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.hub_external_subnet_prefix))
    error_message = "The subnet must be in the format of 'xxx.xxx.xxx.xxx/xx', where xxx is between 0 and 255, and xx is between 0 and 32."
  }
}

variable "hub_external_subnet_gateway" {
  default     = "10.0.0.1"
  description = "Azure gateway IP address to the Internet"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_external_subnet_gateway))
    error_message = "The IP address must be a valid IPv4 format (e.g., 192.168.1.1)."
  }
}

variable "hub_nva_image" {
  default     = "fortiweb"
  description = "NVA image product"
  type        = string
  validation {
    condition     = var.hub_nva_image == "fortigate" || var.hub_nva_image == "fortiweb" || var.hub_nva_image == "fortiadc"
    error_message = "The SKU must be either 'fortiweb', 'fortigate', or 'fortiadc'"
  }
}

variable "hub_nva_management_ip" {
  default     = "10.0.0.4"
  description = "Hub NVA Management IP Address"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_management_ip))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.4)."
  }
}

variable "hub_nva_gateway" {
  default     = "10.0.0.37"
  description = "Hub NVA Gateway IP Address"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_gateway))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.37)."
  }
}

variable "hub_nva_vip_docs" {
  default     = "10.0.0.5"
  description = "Hub NVA Gateway Virtual IP Address for Docs"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_vip_docs))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.5)."
  }
}

variable "hub_nva_vip_dvwa" {
  default     = "10.0.0.6"
  description = "Hub NVA Gateway Virtual IP Address for DVWA"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_vip_dvwa))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.6)."
  }
}

variable "hub_nva_vip_ollama" {
  default     = "10.0.0.7"
  description = "Hub NVA Gateway Virtual IP Address for Ollama"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_vip_ollama))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.7)."
  }
}

variable "hub_nva_vip_video" {
  default     = "10.0.0.8"
  description = "Hub NVA Gateway Virtual IP Address for Video"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_vip_video))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.8)."
  }
}

variable "hub_nva_vip_artifacts" {
  default     = "10.0.0.9"
  description = "Hub NVA Gateway Virtual IP Address for Artifacts"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_vip_artifacts))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.9)."
  }
}

variable "hub_nva_vip_extractor" {
  default     = "10.0.0.10"
  description = "Hub NVA Gateway Virtual IP Address for extractor"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.hub_nva_vip_extractor))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.0.0.10)."
  }
}

variable "gpu_node_pool" {
  default     = false
  description = "Set to true to enable GPU workloads"
  type        = bool
}

variable "spoke_virtual_network_address_prefix" {
  default     = "10.1.0.0/16"
  description = "Spoke Virtual Network Address prefix."
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.spoke_virtual_network_address_prefix))
    error_message = "The subnet must be in the format of 'xxx.xxx.xxx.xxx/xx', where xxx is between 0 and 255, and xx is between 0 and 32."
  }
}

variable "spoke_subnet_name" {
  default     = "spoke_subnet"
  description = "Spoke Subnet Name."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]*$", var.spoke_subnet_name))
    error_message = "The value must consist of alphanumeric characters, underscores, or dashes only."
  }
}

variable "spoke_subnet_prefix" {
  default     = "10.1.1.0/24"
  description = "Spoke Subnet Prefix."
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.spoke_subnet_prefix))
    error_message = "The subnet must be in the format of 'xxx.xxx.xxx.xxx/xx', where xxx is between 0 and 255, and xx is between 0 and 32."
  }
}
variable "spoke_aks_subnet_name" {
  default     = "spoke-aks-subnet"
  description = "Spoke aks Subnet Name."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]*$", var.spoke_aks_subnet_name))
    error_message = "The value must consist of alphanumeric characters, underscores, or dashes only."
  }
}

variable "spoke_aks_subnet_prefix" {
  default     = "10.1.2.0/24"
  description = "Spoke Pod Subnet Prefix."
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.spoke_aks_subnet_prefix))
    error_message = "The subnet must be in the format of 'xxx.xxx.xxx.xxx/xx', where xxx is between 0 and 255, and xx is between 0 and 32."
  }
}

variable "spoke_aks_pod_cidr" {
  default     = "10.244.0.0/16"
  description = "Spoke k8s pod cidr."
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])/(3[0-2]|[12]?[0-9])$", var.spoke_aks_pod_cidr))
    error_message = "The subnet must be in the format of 'xxx.xxx.xxx.xxx/xx', where xxx is between 0 and 255, and xx is between 0 and 32."
  }
}

variable "spoke_aks_node_ip" {
  default     = "10.1.1.4"
  description = "Spoke Container Server IP Address"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.spoke_aks_node_ip))
    error_message = "The IP address must be a valid IPv4 format (e.g., 10.1.1.5)."
  }
}

variable "spoke_check_internet_up_ip" {
  default     = "8.8.8.8"
  description = "Spoke Container Server Checks the Internet at this IP Address"
  type        = string
  validation {
    condition     = can(regex("^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$", var.spoke_check_internet_up_ip))
    error_message = "The IP address must be a valid IPv4 format (e.g., 8.8.8.8)."
  }
}

variable "cloudshell_directory_tenant_id" {
  type        = string
  description = "The tenant ID of the Azure Active Directory."
  sensitive   = true
}

variable "cloudshell_directory_client_id" {
  type        = string
  description = "The client ID of the Azure Active Directory application."
  sensitive   = true
}

variable "cloudshell_admin_username" {
  type        = string
  description = "The username for the Cloud Shell administrator."
  default     = "ubuntu"
}

variable "forticnapp_account" {
  type        = string
  description = "The FortiCnapp account name."
  sensitive   = true
}

variable "forticnapp_subaccount" {
  type        = string
  description = "The FortiCnapp subaccount name."
  sensitive   = true
}

variable "forticnapp_api_key" {
  type        = string
  description = "The FortiCnapp api_key."
  sensitive   = true
}

variable "forticnapp_api_secret" {
  type        = string
  description = "The FortiCnapp api_secret."
  sensitive   = true
}

# CloudShell Authentication Configuration
variable "cloudshell_auth_fqdn" {
  type        = string
  description = "FQDN for CloudShell instance (used for Entra ID redirect URIs)"
  default     = "cloudshell.example.com"

#  validation {
#    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\\.[a-zA-Z]{2,}$", var.cloudshell_auth_fqdn))
#    error_message = "CloudShell FQDN must be a valid domain name."
#  }
}
