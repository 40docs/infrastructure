###############################################################
# Local Values
#
# This file defines local values used across multiple resources
# for configuration consistency and DRY principles.
###############################################################

locals {
  # Standard tags for all resources
  standard_tags = {
    Project     = var.project_name
    Owner       = var.name
    OwnerEmail  = var.owner_email
    Environment = var.production_environment ? "production" : "non-production"
  }

  # Service tags for resource naming
  cloudshell_service_tag = "cloudshell"

  # Common configuration used across resources
  common = {
    project_name = var.project_name
    location     = var.location
    tags = merge(local.standard_tags, {
      Username = var.owner_email
      Name     = var.name
    })
  }

  # VM image configurations
  vm_image = {
    "fortiweb" = {
      publisher       = "fortinet"
      offer           = "fortinet_fortiweb-vm_v5"
      size            = "Standard_F16s_v2"
      size-dev        = "Standard_D4as_v5"
      version         = "latest"
      sku             = "fortinet_fw-vm_payg_v2"
      management-port = "443"
      terms           = true
    }
    "aks" = {
      version      = "latest"
      terms        = false
      offer        = ""
      sku          = ""
      publisher    = ""
      size         = "Standard_E4s_v3"
      size-dev     = "Standard_B8ms"
      cpu-size     = "Standard_E4s_v3"
      cpu-size-dev = "Standard_B8ms"
      gpu-size     = "Standard_NC24s_v3"
      gpu-size-dev = "Standard_NC4as_T4_v3"
    }
    "cloudshell" = {
      terms     = false
      offer     = "ubuntu-24_04-lts"
      sku       = "server"
      publisher = "Canonical"
      size      = "Standard_E4s_v3"
      size-dev  = "Standard_B8ms"
    }
  }
}
