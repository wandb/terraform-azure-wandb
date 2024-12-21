
variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "namespace" {
  type        = string
  description = "Prefix for naming Azure resources"
}

variable "resource_group" {
  type        = string
  description = "Azure resource group to create resources in"
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC issuer URL from deployment cluster"
}

variable "deletion_protection" {
  type        = bool
  description = "Prefix of your bucket"
  default     = true
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

module "secure_storage_connector" {
  source              = "wandb/wandb/azurerm//modules/secure_storage_connector"
  namespace           = var.namespace
  resource_group_name = var.resource_group
  oidc_issuer_url     = var.oidc_issuer_url
  deletion_protection = var.deletion_protection
}

output "storage_account_name" {
  value = module.secure_storage_connector.storage_account_name
}

output "storage_container_name" {
  value = module.secure_storage_connector.storage_container_name
}

output "managed_identity_client_id" {
  value = module.secure_storage_connector.managed_identity_client_id
}

output "tenant_id" {
  value = module.secure_storage_connector.tenant_id
}