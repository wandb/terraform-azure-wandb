locals {
  fqdn                  = var.subdomain == null ? var.domain_name : "${var.subdomain}.${var.domain_name}"
  url_prefix            = var.ssl ? "https" : "http"
  url                   = "${local.url_prefix}://${local.fqdn}"
  create_blob_container = var.blob_container == ""
}


resource "azurerm_resource_group" "default" {
  name     = var.namespace
  location = var.location

  tags = var.tags
}

module "networking" {
  source              = "./modules/networking"
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  tags = var.tags
}

module "database" {
  source              = "./modules/database"
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  database_version             = var.database_version
  database_private_dns_zone_id = module.networking.database_private_dns_zone.id
  database_subnet_id           = module.networking.database_subnet.id

  tags = var.tags
}

module "storage" {
  source              = "./modules/storage"
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  tags                = var.tags
}

module "app_lb" {
  source         = "./modules/app_lb"
  namespace      = var.namespace
  resource_group = azurerm_resource_group.default
  location       = azurerm_resource_group.default.location
  network        = module.networking.network
  public_subnet  = module.networking.public_subnet
}

module "app_aks" {
  source              = "./modules/app_aks"
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  gateway           = module.app_lb.gateway
  cluster_subnet_id = module.networking.private_subnet.id

  tags = var.tags
}

locals {
  cluster_identity_principal_id = module.app_aks.cluster.identity.0.principal_id
  # TODO: this might break if Azure changes the name
  app_gateway_uid_name = "ingressapplicationgateway-${var.namespace}-k8s"
}

locals {
  blob_container = local.create_blob_container ? "${module.storage.account.name}/${module.storage.container.name}" : var.blob_container
  queue          = var.use_internal_queue ? "internal://" : "az://${module.storage.account.name}/${module.storage.queue.name}"
}

module "aks_app" {
  source = "github.com/wandb/terraform-kubernetes-wandb?ref=genericenv"

  license = var.license

  host                       = local.url
  bucket                     = "az://${local.blob_container}"
  bucket_queue               = local.queue
  database_connection_string = "mysql://${module.database.connection_string}"
  # redis_connection_string    = local.redis_connection_string
  # redis_ca_cert              = local.redis_certificate

  oidc_client_id   = var.oidc_client_id
  oidc_issuer      = var.oidc_issuer
  oidc_auth_method = var.oidc_auth_method

  wandb_image   = var.wandb_image
  wandb_version = var.wandb_version

  other_wandb_env = {
    "AZURE_STORAGE_KEY"     = module.storage.account.primary_access_key,
    "AZURE_STORAGE_ACCOUNT" = module.storage.account.name,
  }

  # If we dont wait, tf will start trying to deploy while the work group is
  # still spinning up
  depends_on = [
    module.database,
    # module.redis,
    module.storage,
    module.app_aks,
  ]
}

data "azurerm_user_assigned_identity" "wandb" {
  resource_group_name = module.app_aks.cluster.node_resource_group
  # The ingress_application_gateway creates a user identity with this name
  # TODO: Figure out how to not rely on this convention
  name = "ingressapplicationgateway-${module.app_aks.cluster.name}"
}

resource "azurerm_role_assignment" "ra3" {
  scope                = module.app_lb.gateway.id
  role_definition_name = "Contributor"
  # TODO: we can likely use: data.azurerm_application_gateway.wandb.identity.identity_ids ?
  principal_id = data.azurerm_user_assigned_identity.wandb.principal_id
  depends_on   = [module.app_aks, module.app_lb]
}

resource "azurerm_role_assignment" "ra4" {
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Reader"
  # TODO: we can likely use: data.azurerm_application_gateway.wandb.identity.identity_ids ?
  principal_id = data.azurerm_user_assigned_identity.wandb.principal_id
  depends_on   = [module.app_aks, module.app_lb]
}

module "cert_manager" {
  source    = "./modules/cert_manager"
  namespace = var.namespace

  ingress_class              = "azure/application-gateway"
  cert_manager_email         = "sysadmin@wandb.com"
  cert_manager_chart_version = "v1.9.1"
  tags                       = var.tags

  depends_on = [module.app_aks]
}

module "app_ingress" {
  source = "./modules/app_ingress"
  fqdn   = local.fqdn

  depends_on = [
    module.aks_app,
    module.cert_manager,
    module.app_aks,
  ]
}
