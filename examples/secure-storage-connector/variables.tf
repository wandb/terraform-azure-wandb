variable "subscription_id" {
    description = "The subscription ID to use for the Azure resources"
    type        = string
}

variable "tenant_id" {
    description = "The tenant ID to use for the Azure resources"
    type        = string
}

variable "namespace" {
    description = "The prefix for naming Azure resources"
    type        = string
}

variable "resource_group_name" {
    description = "The name of the resource group in which to create the managed identity and storage account."
    type        = string
}

variable "oidc_issuer_url" {
    description = "The OIDC issuer URL from the AKS cluster that is meant to connect to this container. Make sure to include the trailing '/'"
    type        = string
}