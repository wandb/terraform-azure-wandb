variable "namespace" {
  type        = string
  description = "Prefix to use when creating resources"
}

variable "oidc_issuer_url" {
  type        = string
  description = "OIDC Issuer URL from server deployment's AKS Cluster. Make sure to include the trailing '/'"
}

variable "deletion_protection" {
  description = "If the instance should have deletion protection enabled. The storage container can't be deleted when this value is set to `true`."
  type        = bool
  default     = true
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the managed identity and storage account."
}

variable "subscription_id" {
  type    = string
  default = null
}
