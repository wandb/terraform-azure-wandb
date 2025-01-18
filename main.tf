locals {
  fqdn       = var.subdomain == null ? var.domain_name : "${var.subdomain}.${var.domain_name}"
  url_prefix = var.ssl ? "https" : "http"
  url        = "${local.url_prefix}://${local.fqdn}"

  redis_capacity             = coalesce(var.redis_capacity, local.deployment_size[var.size].cache)
  database_sku_name          = coalesce(var.database_sku_name, local.deployment_size[var.size].db)
  kubernetes_instance_type   = coalesce(var.kubernetes_instance_type, local.deployment_size[var.size].node_instance)
  kubernetes_min_node_per_az = coalesce(var.kubernetes_min_node_per_az, local.deployment_size[var.size].min_node_count)
  kubernetes_max_node_per_az = coalesce(var.kubernetes_max_node_per_az, local.deployment_size[var.size].max_node_count)
}

resource "azurerm_resource_group" "default" {
  name     = var.namespace
  location = var.location

  tags = var.tags
}

module "identity" {
  source         = "./modules/identity"
  namespace      = var.namespace
  otel_identity  = var.azuremonitor
  resource_group = azurerm_resource_group.default
  location       = azurerm_resource_group.default.location
}

module "networking" {
  source              = "./modules/networking"
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  private_link        = var.create_private_link
  allowed_ip_ranges   = var.allowed_ip_ranges
  tags                = var.tags
}

module "database" {
  source    = "./modules/database"
  namespace = var.namespace

  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location

  database_availability_mode   = var.database_availability_mode
  database_version             = var.database_version
  database_private_dns_zone_id = module.networking.database_private_dns_zone.id
  database_subnet_id           = module.networking.database_subnet.id
  sku_name                     = local.database_sku_name
  deletion_protection          = var.deletion_protection

  database_key_id = try(module.vault.vault_internal_keys[module.vault.vault_key_map.database].id, null)
  identity_ids    = module.identity.identity.id
  tags = var.tags

  depends_on = [module.networking]
}

module "redis" {
  source              = "./modules/redis"
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  capacity            = local.redis_capacity
  depends_on          = [module.networking]

  tags = var.tags
}

module "vault" {
  source = "./modules/vault"

  identity_object_id = module.identity.identity.principal_id
  location           = azurerm_resource_group.default.location
  namespace          = var.namespace
  resource_group     = azurerm_resource_group.default

  enable_database_vault_key = var.enable_database_vault_key
  enable_storage_vault_key  = var.enable_storage_vault_key

  tags = var.tags
}

module "storage" {
  source = "./modules/storage"

  count               = 1
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  create_queue        = !var.use_internal_queue
  identity_ids        = module.identity.identity.id
  deletion_protection = var.deletion_protection

  storage_key_id               = try(module.vault.vault_internal_keys[module.vault.vault_key_map.storage].id, null)
  disable_storage_vault_key_id = var.disable_storage_vault_key_id

  tags = var.tags
}

module "app_lb" {
  source = "./modules/app_lb"

  namespace      = var.namespace
  resource_group = azurerm_resource_group.default
  location       = azurerm_resource_group.default.location
  network        = module.networking.network
  public_subnet  = module.networking.public_subnet
  private_subnet = module.networking.private_subnet.id
  private_link   = var.create_private_link

  tags = var.tags
}

data "azapi_resource_list" "az_zones" {
  parent_id = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
  type      = "Microsoft.Compute/skus@2021-07-01"

  response_export_values = ["value"]
}

locals {
  vm_skus = [
    for sku in jsondecode(data.azapi_resource_list.az_zones.output).value :
    sku if(
      sku.resourceType == "virtualMachines" &&
      lower(sku.locations[0]) == lower(azurerm_resource_group.default.location) &&
      sku.name == local.kubernetes_instance_type
    )
  ]

  num_zones        = var.node_pool_zones != null ? length(var.node_pool_zones) : var.node_pool_num_zones
  restricted_zones = length(local.vm_skus[0].restrictions) > 0 ? local.vm_skus[0].restrictions[0].restrictionInfo.zones : []
  all_zones        = local.vm_skus[0].locationInfo[0].zones
  valid_zones      = setsubtract(local.all_zones, local.restricted_zones)
  node_pool_zones  = var.node_pool_zones != null ? var.node_pool_zones : slice(sort(local.valid_zones), 0, local.num_zones)
}

module "app_aks" {
  source     = "./modules/app_aks"
  depends_on = [module.app_lb]

  cluster_subnet_id       = module.networking.private_subnet.id
  etcd_key_vault_key_id   = module.vault.etcd_key_id
  gateway                 = module.app_lb.gateway
  identity                = module.identity.identity
  location                = azurerm_resource_group.default.location
  namespace               = var.namespace
  node_pool_min_vm_per_az = local.kubernetes_min_node_per_az
  node_pool_max_vm_per_az = local.kubernetes_max_node_per_az
  node_pool_vm_size       = local.kubernetes_instance_type
  node_pool_zones         = local.node_pool_zones
  public_subnet           = module.networking.public_subnet
  resource_group          = azurerm_resource_group.default
  sku_tier                = var.cluster_sku_tier
  tags                    = var.tags
}
locals {
  service_account_name         = "wandb-app"
  private_endpoint_approval_sa = "private-endpoint-sa"
  otel_sa_name                 = "wandb-otel-daemonset"
}

resource "azurerm_federated_identity_credential" "app" {
  parent_id           = module.identity.identity.id
  name                = "${var.namespace}-app-credentials"
  resource_group_name = azurerm_resource_group.default.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.app_aks.oidc_issuer_url
  subject             = "system:serviceaccount:default:${local.service_account_name}"
}

# aks workload identity resources for private endpoint approval application
module "pod_identity" {
  count          = length(var.allowed_subscriptions) > 0 ? 1 : 0
  source         = "./modules/identity"
  depends_on     = [module.app_aks]
  namespace      = "${var.namespace}-private-endpoint-pod"
  resource_group = azurerm_resource_group.default
  location       = azurerm_resource_group.default.location
}

resource "azurerm_federated_identity_credential" "pod" {
  count               = length(var.allowed_subscriptions) > 0 ? 1 : 0
  parent_id           = module.pod_identity[0].identity.id
  name                = "${var.namespace}-app-credentials"
  resource_group_name = azurerm_resource_group.default.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.app_aks.oidc_issuer_url
  subject             = "system:serviceaccount:default:${local.private_endpoint_approval_sa}"

}

resource "azurerm_role_assignment" "gateway_role" {
  count                = length(var.allowed_subscriptions) > 0 ? 1 : 0
  scope                = module.app_lb.gateway.id
  role_definition_name = "Contributor"
  principal_id         = module.pod_identity[0].identity.principal_id

}

module "cron_job" {
  count  = length(var.allowed_subscriptions) > 0 ? 1 : 0 # private endpoint approval application deployed as a cronjob in default namespace
  source = "./modules/cron_job"

  namespace              = "default"
  client_id              = module.pod_identity[0].identity.client_id
  serviceaccountName     = local.private_endpoint_approval_sa
  subscriptionId         = data.azurerm_subscription.current.subscription_id
  resourceGroupName      = azurerm_resource_group.default.name
  applicationGatewayName = module.app_lb.gateway.name
  allowedSubscriptions   = var.allowed_subscriptions
  depends_on             = [module.app_lb, module.pod_identity]
}

resource "azurerm_role_assignment" "otel_role" {
  count                = var.azuremonitor ? 1 : 0
  scope                = azurerm_resource_group.default.id
  role_definition_name = "Contributor"
  principal_id         = module.identity.otel_identity.principal_id
}

resource "azurerm_federated_identity_credential" "otel_app" {
  count               = var.azuremonitor ? 1 : 0
  parent_id           = module.identity.otel_identity.id
  name                = "${var.namespace}-otel-app-credentials"
  resource_group_name = azurerm_resource_group.default.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = module.app_aks.oidc_issuer_url
  subject             = "system:serviceaccount:default:${local.otel_sa_name}"
}

module "cert_manager" {
  source    = "./modules/cert_manager"
  namespace = var.namespace

  ingress_class              = "azure/application-gateway"
  cert_manager_email         = "sysadmin@wandb.com"
  cert_manager_chart_version = "v1.16.1"
  tags                       = var.tags

  depends_on = [module.app_aks]
}

module "clickhouse" {
  count               = var.clickhouse_private_endpoint_service_name != "" ? 1 : 0
  source              = "./modules/clickhouse"
  namespace           = var.namespace
  resource_group_name = azurerm_resource_group.default.name
  location            = azurerm_resource_group.default.location
  network_id          = module.networking.network.id
  private_subnet_id   = module.networking.private_subnet.id

  clickhouse_private_endpoint_service_name = var.clickhouse_private_endpoint_service_name
  clickhouse_region                        = var.clickhouse_region
}

locals {
  use_customer_bucket = (
    var.storage_account != "" &&
    var.blob_container != "" &&
    var.storage_key != ""
  )
  default_bucket_config = {
    provider  = "az"
    name      = var.storage_account
    path      = "${var.blob_container}/${var.bucket_path}"
    accessKey = var.storage_key
  }

  bucket_config = var.external_bucket != null ? var.external_bucket : (local.use_customer_bucket ? local.default_bucket_config : null)
  weave_trace_service_account_name = "wandb-weave-trace"
}

module "wandb" {
  source  = "wandb/wandb/helm"
  version = "2.0.0"

  depends_on = [
    module.app_aks,
    module.cert_manager,
    module.database,
    module.storage,
  ]
  operator_chart_version = var.operator_chart_version
  controller_image_tag   = var.controller_image_tag
  enable_helm_release    = var.enable_helm_release

  spec = {
    values = {
      global = {
        host          = local.url
        license       = var.license
        cloudProvider = "azure"
        bucket        = local.bucket_config == null ? {} : local.bucket_config
        defaultBucket = {
          provider  = "az"
          name      = module.storage[0].account.name
          path      = "${module.storage[0].container.name}/${var.bucket_path}"
          accessKey = module.storage[0].account.primary_access_key
        }
        azureIdentityForBucket = {
          clientID = module.identity.identity.client_id
          tenantID = module.identity.identity.tenant_id
        }

        mysql = {
          host     = module.database.address
          database = module.database.database_name
          user     = module.database.username
          password = module.database.password
          port     = 3306
        }

        redis = {
          host     = module.redis.instance.hostname
          password = module.redis.instance.primary_access_key
          port     = module.redis.instance.port
        }

        extraEnv = var.other_wandb_env

      }

      app = {
        extraEnv = {
          "GORILLA_CUSTOMER_SECRET_STORE_AZ_CONFIG_VAULT_URI" = module.vault.vault.vault_uri,
          "GORILLA_CUSTOMER_SECRET_STORE_SOURCE"              = "az-secretmanager://wandb",
        }
        pod = {
          labels = { "azure.workload.identity/use" = "true" }
        }
        serviceAccount = {
          name        = local.service_account_name
          annotations = { "azure.workload.identity/client-id" = module.identity.identity.client_id }
          labels      = { "azure.workload.identity/use" = "true" }
        }
        internalJWTMap = [
          {
            subject = "system:serviceaccount:default:${local.weave_trace_service_account_name}",
            issuer  = var.kubernetes_cluster_oidc_issuer_url
          }
        ]
      }

      console = {
        extraEnv = {
          "BUCKET_ACCESS_IDENTITY" = "CLIENT_ID=${module.identity.identity.client_id} - TENANT_ID=${module.identity.identity.tenant_id}"
        }
      }

      ingress = {
        // TODO: For now we will use the existing issuer. We can move this into
        // the operator after testing. Trying to reduce the diff.
        issuer = { create = false }

        annotations = {
          "kubernetes.io/ingress.class"                 = "azure/application-gateway"
          "cert-manager.io/cluster-issuer"              = "cert-issuer"
          "cert-manager.io/acme-challenge-type"         = "http01"
          "appgw.ingress.kubernetes.io/request-timeout" = "300"
        }

        tls = [
          { hosts = [trimprefix(trimprefix(local.url, "https://"), "http://")], secretName = "wandb-ssl-cert" }
        ]
      }

      otel = {
        daemonset = var.azuremonitor ? {
          pod            = { labels = { "azure.workload.identity/use" = "true" } }
          serviceAccount = { annotations = { "azure.workload.identity/client-id" = module.identity.otel_identity.client_id } }
          config = {
            receivers = {
              azuremonitor = {
                subscription_id      = data.azurerm_subscription.current.subscription_id
                resource_groups      = [var.namespace]
                auth                 = "workload_identity"
                tenant_id            = "$${env:AZURE_TENANT_ID}"
                client_id            = "$${env:AZURE_CLIENT_ID}"
                federated_token_file = "$${env:AZURE_FEDERATED_TOKEN_FILE}"
                services             = ["Microsoft.DBforMySQL/flexibleServers", "Microsoft.Cache/Redis"]
              }
            }
            service = {
              pipelines = {
                metrics = {
                  receivers = ["hostmetrics", "k8s_cluster", "kubeletstats", "azuremonitor"]
                }
              }
            }
          }
          } : {
          pod            = {}
          serviceAccount = {}
          config = {
            receivers = {}
            service   = {}
          }
        }
      }

      weave = {
        persistence = {
          provider = "azurefile"
        }
      }

      mysql = { install = false }
      redis = { install = false }

      parquet = {
        extraEnv = var.parquet_wandb_env
      }
    }
  }
}
