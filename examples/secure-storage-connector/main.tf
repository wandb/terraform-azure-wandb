provider "azurerm" {
  features {} 
  tenant_id           = var.tenant_id
}

module "secure_storage_connector" {
  source              = "../../modules/secure_storage_connector"
  namespace           = var.namespace
  resource_group_name = var.resource_group_name
  oidc_issuer_url     = var.oidc_issuer_url
  subscription_id     = var.subscription_id
}