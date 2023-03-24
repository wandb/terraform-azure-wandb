output "fqdn" {
  value       = local.fqdn
  description = "The FQDN to the W&B application"
}

output "address" {
  value = module.app_lb.address
}

output "url" {
  value       = local.url
  description = "The URL to the W&B application"
}

output "cluster_host" {
  value = module.app_aks.cluster_host
}

output "cluster_client_certificate" {
  value = module.app_aks.cluster_client_certificate
}

output "cluster_client_key" {
  value = module.app_aks.cluster_client_key
}

output "cluster_ca_certificate" {
  value     = module.app_aks.cluster_ca_certificate
  sensitive = true
}

output "storage_account" {
  value = var.storage_account == "" ? module.storage.0.account.name : var.storage_account
}

output "storage_container" {
  value = var.blob_container == "" ? module.storage.0.container.name : var.blob_container
}

output "external_bucket" {
  value = var.external_bucket != "" ? var.external_bucket : ""
}
