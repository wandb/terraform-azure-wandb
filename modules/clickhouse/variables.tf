variable "namespace" {
  type        = string
  description = "Friendly name prefix used for tagging and naming Azure resources."
}

variable "resource_group_name" {
  type        = string
  description = "The name of the resource group in which to create the network."
}

variable "location" {
  type        = string
  description = "Specifies the supported Azure location where the resource exists."
}

variable "network_id" {
  type        = string
  description = "The virtual network id used for all resources"
}

variable "private_subnet_id" {
  type        = string
  description = "Specifies the supported Azure subnet id where the resource exists."
}

variable "clickhouse_private_endpoint_service_name" {
  type        = string
  description = "ClickHouse private endpoint 'Service name' (ends in .azure.privatelinkservice)."
  default     = ""

  validation {
    condition     = can(regex("\\.azure\\.privatelinkservice$", var.clickhouse_private_endpoint_service_name))
    error_message = "ClickHouse Service name must end in '.azure.privatelinkservice'."
  }
}

variable "clickhouse_region" {
  type        = string
  description = "ClickHouse region (eastus2, westus3, etc)."
  default     = ""

  validation {
    condition     = length(var.clickhouse_region) > 0
    error_message = "Clickhouse Region should always be set if the private endpoint service name is specified."
  }
}
