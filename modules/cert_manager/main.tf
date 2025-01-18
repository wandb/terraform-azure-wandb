locals {
  issuer_name       = "${var.namespace}-letsencrypt"
  default_namespace = "default"
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  chart            = "cert-manager"
  repository       = "https://charts.jetstack.io"
  version          = var.cert_manager_chart_version
  namespace        = local.default_namespace
  create_namespace = true

  set {
    name  = "installCRDs"
    value = true
  }
}

# It requires creating a module and referencing a custom helm chart for the
# cert-issuer. It's not ideal given the amount of effort that has to be used to
# create it for custom needs, but once it's created, it's a reusable, modular
# solution.
# https://stackoverflow.com/questions/69765121/how-to-avoid-clusterissuer-dependency-on-helm-cert-manager-crds-in-terraform-pla
resource "helm_release" "cert_issuer" {
  name      = "cert-issuer"
  chart     = "${path.module}/cert-issuer"
  namespace = local.default_namespace

  set {
    name  = "fullnameOverride"
    value = local.issuer_name
  }

  set {
    name  = "privateKeySecretRef"
    value = local.issuer_name
  }

  set {
    name  = "ingressClass"
    value = var.ingress_class
  }

  set {
    name  = "acmeEmail"
    value = var.cert_manager_email
  }

  set {
    name  = "acmeServer"
    value = var.acme_server
  }

  depends_on = [helm_release.cert_manager]
}
