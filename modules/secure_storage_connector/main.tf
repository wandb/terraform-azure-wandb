provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_client_config" "current" {
}

data "azurerm_resource_group" "group" {
  name = var.resource_group_name
}

resource "azurerm_user_assigned_identity" "default" {
  name                = "${var.namespace}-identity"
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
}

resource "azurerm_federated_identity_credential" "app" {
  parent_id           = azurerm_user_assigned_identity.default.id
  name                = "${var.namespace}-federated-credential"
  resource_group_name = data.azurerm_resource_group.group.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = var.oidc_issuer_url
  subject             = "system:serviceaccount:default:wandb-app"
}

module "storage" {
  depends_on = [azurerm_user_assigned_identity.default]

  source = "../storage"

  create_queue        = false
  namespace           = var.namespace
  location            = data.azurerm_resource_group.group.location
  resource_group_name = data.azurerm_resource_group.group.name
  blob_container_name = var.namespace
  deletion_protection = var.deletion_protection
  storage_key_id      = null
  identity_ids        = ""
}

resource "azurerm_role_assignment" "account" {
  depends_on = [module.storage]

  scope                = module.storage.account.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = azurerm_user_assigned_identity.default.principal_id
}

resource "azurerm_role_assignment" "container" {
  depends_on = [module.storage]

  scope                = module.storage.account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = azurerm_user_assigned_identity.default.principal_id
}
