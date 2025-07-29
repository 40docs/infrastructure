locals {
  gpu-operator_repo_fqdn = "git@github.com:${var.github_org}/${var.manifests_infrastructure_repo_name}.git"
}

resource "azurerm_kubernetes_flux_configuration" "gpu-operator" {
  count                             = var.gpu_node_pool ? 1 : 0
  name                              = "gpu-operator"
  cluster_id                        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  namespace                         = "cluster-config"
  scope                             = "cluster"
  continuous_reconciliation_enabled = true
  git_repository {
    url                      = local.gpu-operator_repo_fqdn
    reference_type           = "branch"
    reference_value          = "main"
    sync_interval_in_seconds = 60
    ssh_private_key_base64   = base64encode(var.manifests_infrastructure_ssh_private_key)
  }
  kustomizations {
    name                       = "gpu-operator"
    recreating_enabled         = true
    garbage_collection_enabled = true
    sync_interval_in_seconds   = 60
    path                       = "./gpu-operator"
  }
  depends_on = [
    azurerm_kubernetes_cluster_extension.flux_extension
  ]
}
