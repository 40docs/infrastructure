resource "kubernetes_namespace" "ingress-helper" {
  depends_on = [
    azurerm_kubernetes_cluster.kubernetes_cluster
  ]
  metadata {
    name = "ingress-helper"
    labels = {
      name = "ingress-helper"
    }
  }
}

resource "kubernetes_secret" "ingress-helper_fortiweb_login_secret" {
  count = var.application_docs ? 1 : 0
  metadata {
    name      = "fortiweb-login-secret"
    namespace = kubernetes_namespace.ingress-helper.metadata[0].name
  }
  data = {
    username = var.hub_nva_username
    password = var.hub_nva_password
  }
  type = "Opaque"
}
