###############################################################
# Azure Marketplace Agreement Acceptance
#
# This file handles acceptance of Azure Marketplace terms
# for VM images that require explicit agreement.
###############################################################

resource "null_resource" "marketplace_agreement" {
  for_each = {
    for name, config in local.vm_image : name => config
    if config.terms == true
  }

  provisioner "local-exec" {
    command = "az vm image terms accept --publisher ${each.value.publisher} --offer ${each.value.offer} --plan ${each.value.sku} || true"
  }

  triggers = {
    publisher = each.value.publisher
    offer     = each.value.offer
    sku       = each.value.sku
    terms     = each.value.terms
  }
}
