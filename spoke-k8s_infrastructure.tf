locals {
  #infrastructure_repo_fqdn = "git@github.com:${var.github_org}/${var.manifests_infrastructure_repo_name}.git"
  infrastructure_repo_fqdn = "https://github.com/${var.github_org}/${var.manifests_infrastructure_repo_name}.git"
}

resource "azurerm_kubernetes_flux_configuration" "infrastructure" {
  name                              = "infrastructure"
  cluster_id                        = azurerm_kubernetes_cluster.kubernetes_cluster.id
  namespace                         = "cluster-config"
  scope                             = "cluster"
  continuous_reconciliation_enabled = true
  git_repository {
    url                      = local.infrastructure_repo_fqdn
    reference_type           = "branch"
    reference_value          = "main"
    sync_interval_in_seconds = 60
    #ssh_private_key_base64   = base64encode(var.manifests_infrastructure_ssh_private_key)
  }
  kustomizations {
    name                       = "infrastructure"
    recreating_enabled         = true
    garbage_collection_enabled = true
    sync_interval_in_seconds   = 60
  }
  kustomizations {
    name                       = "cert-manager-clusterissuer"
    recreating_enabled         = true
    garbage_collection_enabled = true
    sync_interval_in_seconds   = 60
    path                       = "./cert-manager-clusterissuer"
    depends_on                 = ["infrastructure"]
  }
  depends_on = [
    azurerm_kubernetes_cluster_extension.flux_extension,
    kubernetes_namespace.lacework-agent
  ]
}
