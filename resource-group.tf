###############################################################
# Resource Group Configuration
#
# This file defines the main Azure Resource Group that contains
# all resources for this infrastructure deployment.
###############################################################

resource "azurerm_resource_group" "azure_resource_group" {
  # ts:skip=AC_AZURE_0389 in development we allow deletion of resource groups
  name     = var.project_name
  location = var.location

  tags = merge(local.standard_tags, {
    CreatedOnDate = "2025-08-02"
  })

  lifecycle {
    ignore_changes = [
      tags["CreatedOnDate"],
    ]
  }
}
