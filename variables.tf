##########################################
# Common                                 #
##########################################
variable "namespace" {
  type        = string
  description = "String used for prefix resources."
}

variable "location" {
  type = string
}

variable "tags" {
  default     = {}
  type        = map(string)
  description = "Map of tags for resource"
}

variable "deletion_protection" {
  description = "If the instance should have deletion protection enabled. The database / Bucket can't be deleted when this value is set to `true`."
  type        = bool
  default     = true
}

variable "use_internal_queue" {
  type        = bool
  description = "Uses an internal redis queue instead of using azure queue."
  default     = false
}

variable "size" {
  default     = "small"
  description = "Deployment size"
  nullable    = true
  type        = string
}

variable "license" {
  type        = string
  description = "Your wandb/local license"
}

variable "other_wandb_env" {
  type        = map(any)
  description = "Extra environment variables for W&B"
  default     = {}
}

##########################################
# Operator                               #
##########################################
variable "operator_chart_version" {
  type        = string
  description = "Version of the operator chart to deploy"
  default     = "1.3.4"
}

variable "controller_image_tag" {
  type        = string
  description = "Tag of the controller image to deploy"
  default     = "1.14.0"
}

variable "enable_helm_release" {
  type        = bool
  default     = true
  description = "Enable or disable applying and releasing Helm chart"
}

##########################################
# DNS                                    #
##########################################
variable "domain_name" {
  type        = string
  default     = null
  description = "Domain for accessing the Weights & Biases UI."
}

variable "subdomain" {
  type        = string
  default     = null
  description = "Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route."
}

variable "ssl" {
  type        = bool
  default     = true
  description = "Enable SSL certificate"
}

##########################################
# Database                               #
##########################################
variable "database_version" {
  description = "Version for MySQL"
  type        = string
  default     = "5.7"
}

variable "database_availability_mode" {
  description = ""
  type        = string
  default     = "SameZone"

  validation {
    condition     = contains(["ZoneRedundant", "SameZone"], var.database_availability_mode)
    error_message = "Possible values: \"ZoneRedundant\"; \"SameZone\"."
  }
}

variable "database_sku_name" {
  type        = string
  default     = null
  description = "Specifies the SKU Name for this MySQL Server. Defaults to null and value from deployment-size.tf is used"
}

##########################################
# Redis                                  #
##########################################
variable "redis_capacity" {
  type        = number
  description = "Number indicating size of an redis instance. Defaults to null and value from deployment-size.tf is used"
  default     = null
}

##########################################
# External Bucket                        #
##########################################
# Most users will not need these settings. They are ment for users who want a
# bucket in a different account.

variable "blob_container" {
  type        = string
  description = "Use an existing bucket."
  default     = ""
}

variable "storage_account" {
  type        = string
  description = "Azure storage account name"
  default     = ""
}

variable "storage_key" {
  type        = string
  description = "Azure primary storage access key"
  default     = ""
}

variable "external_bucket" {
  description = "config an external bucket"
  type        = any
  default     = null
}

##########################################
# Bucket path                            #
##########################################
# This setting is meant for users who want to store all of their instance-level
# bucket's data at a specific path within their bucket. It can be set both for
# external buckets or the bucket created by this module.
variable "bucket_path" {
  description = "path of where to store data for the instance-level bucket"
  type        = string
  default     = ""
}

##########################################
# K8s                                    #
##########################################
variable "kubernetes_instance_type" {
  description = "Instance type for primary node group. Defaults to null and value from deployment-size.tf is used"
  type        = string
  default     = null
}

variable "kubernetes_min_node_per_az" {
  description = "Minimum number of nodes for the AKS cluster. Defaults to null and value from deployment-size.tf is used"
  type        = number
  default     = null
}

variable "kubernetes_max_node_per_az" {
  description = "Maximum number of nodes for the AKS cluster. Defaults to null and value from deployment-size.tf is used"
  type        = number
  default     = null
}

variable "cluster_sku_tier" {
  type        = string
  description = "The Azure AKS SKU Tier to use for this cluster (https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers)"
  default     = "Free"
}

variable "node_pool_zones" {
  type        = list(string)
  description = "Availability zones for the node pool"
  default     = null
}

variable "node_pool_num_zones" {
  type        = number
  description = "Number of availability zones to use for the node pool when node_pool_zones is not set. If neither are set, 3 zones will be used"
  default     = 2
}

variable "node_max_pods" {
  type        = number
  description = "Maximum number of pods per node"
  default     = 30
}

###########################################
# Application gateway private link        #
###########################################
variable "create_private_link" {
  type        = bool
  default     = false
  description = "Use for the azure private link."
}

variable "allowed_subscriptions" {
  type        = string
  description = "List of allowed customer subscriptions coma seperated values"
  default     = ""
}
##########################################
# Network                                #
##########################################

variable "allowed_ip_ranges" {
  description = "Allowed public IP addresses or CIDR ranges."
  type        = list(string)
  default     = []
}

variable "parquet_wandb_env" {
  type        = map(string)
  description = "Extra environment variables for W&B"
  default     = {}
}

##########################################
# vault key                              #
##########################################

variable "enable_storage_vault_key" {
  type        = bool
  default     = false
  description = "Flag to enable managed key encryption for the storage account."
}

variable "disable_storage_vault_key_id" {
  type        = bool
  default     = false
  description = "Flag to disable the `customer_managed_key` block, the properties 'encryption.identity, encryption.keyvaultproperties' cannot be updated in a single operation."
}

variable "enable_database_vault_key" {
  type        = bool
  default     = false
  description = "Flag to enable managed key encryption for the database. Once enabled, cannot be disabled."
}

## To support otel azure monitor sql and redis metrics need operator-wandb chart minimum version 0.14.0 
variable "azuremonitor" {
  type    = bool
  default = false
}

###########################################
# ClickHouse endpoint                     #
###########################################
variable "clickhouse_private_endpoint_service_name" {
  type        = string
  description = "ClickHouse private endpoint 'Service name' (ends in .azure.privatelinkservice)."
  default     = ""
}

variable "clickhouse_region" {
  type        = string
  description = "ClickHouse region (eastus2, westus3, etc)."
  default     = ""
}

###########################################
# Internal Service                        #
###########################################
variable "kubernetes_cluster_oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL for the Kubernetes cluster. Can be determined using `kubectl get --raw /.well-known/openid-configuration`"
  default     = ""
}
