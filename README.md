# Weights & Biases Azure Module

This is a Terraform module for provisioning a Weights & Biases Cluster on Azure.
Weights & Biases Server is our self-hosted distribution of wandb.ai. It offers
enterprises a private instance of the Weights & Biases application, with no
resource limits and with additional enterprise-grade architectural features like
audit logging and single sign-on.

## About This Module

## Pre-requisites

This module is intended to run in an Azure account with minimal
preparation, however it does have the following pre-requisites:

### Terraform version >= 1.9

### Credentials / Permissions

## How to Use This Module

## Cluster Sizing

By default, the type of kubernetes instances, number of instances, redis cluster size, and database instance sizes are
standardized via configurations in [./deployment-size.tf](deployment-size.tf), and is configured via the `size` input
variable.

Available sizes are, `small`, `medium`, `large`, `xlarge`, and `xxlarge`.  Default is `small`.

All the values set via `deployment-size.tf` can be overridden by setting the appropriate input variables.

- `kubernetes_instance_type` - The instance type for the EKS nodes
- `kubernetes_min_node_per_az` - The minimum number of nodes in the EKS cluster
- `kubernetes_max_node_per_az` - The maximum number of nodes in the EKS cluster
- `redis_capacity` - The instance type for the redis cluster
- `database_sku_name` - The instance type for the database

## Examples

We have included documentation and reference examples for additional common
installation scenarios for Weights & Biases, as well as examples for supporting
resources that lack official modules.

- Route

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.9 |
| <a name="requirement_azapi"></a> [azapi](#requirement\_azapi) | ~> 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.17 |
| <a name="requirement_helm"></a> [helm](#requirement\_helm) | ~> 2.6 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | ~> 1.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.17 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_app_aks"></a> [app\_aks](#module\_app\_aks) | ./modules/app_aks | n/a |
| <a name="module_app_lb"></a> [app\_lb](#module\_app\_lb) | ./modules/app_lb | n/a |
| <a name="module_cert_manager"></a> [cert\_manager](#module\_cert\_manager) | ./modules/cert_manager | n/a |
| <a name="module_clickhouse"></a> [clickhouse](#module\_clickhouse) | ./modules/clickhouse | n/a |
| <a name="module_cron_job"></a> [cron\_job](#module\_cron\_job) | ./modules/cron_job | n/a |
| <a name="module_database"></a> [database](#module\_database) | ./modules/database | n/a |
| <a name="module_identity"></a> [identity](#module\_identity) | ./modules/identity | n/a |
| <a name="module_networking"></a> [networking](#module\_networking) | ./modules/networking | n/a |
| <a name="module_pod_identity"></a> [pod\_identity](#module\_pod\_identity) | ./modules/identity | n/a |
| <a name="module_redis"></a> [redis](#module\_redis) | ./modules/redis | n/a |
| <a name="module_storage"></a> [storage](#module\_storage) | ./modules/storage | n/a |
| <a name="module_vault"></a> [vault](#module\_vault) | ./modules/vault | n/a |
| <a name="module_wandb"></a> [wandb](#module\_wandb) | wandb/wandb/helm | 2.0.0 |

## Resources

| Name | Type |
|------|------|
| [azapi_resource_list.az_zones](https://registry.terraform.io/providers/azure/azapi/latest/docs/data-sources/resource_list) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_ip_ranges"></a> [allowed\_ip\_ranges](#input\_allowed\_ip\_ranges) | Allowed public IP addresses or CIDR ranges. | `list(string)` | `[]` | no |
| <a name="input_allowed_subscriptions"></a> [allowed\_subscriptions](#input\_allowed\_subscriptions) | List of allowed customer subscriptions coma seperated values | `string` | `""` | no |
| <a name="input_azuremonitor"></a> [azuremonitor](#input\_azuremonitor) | # To support otel azure monitor sql and redis metrics need operator-wandb chart minimum version 0.14.0 | `bool` | `false` | no |
| <a name="input_blob_container"></a> [blob\_container](#input\_blob\_container) | Use an existing bucket. | `string` | `""` | no |
| <a name="input_bucket_path"></a> [bucket\_path](#input\_bucket\_path) | path of where to store data for the instance-level bucket | `string` | `""` | no |
| <a name="input_clickhouse_private_endpoint_service_name"></a> [clickhouse\_private\_endpoint\_service\_name](#input\_clickhouse\_private\_endpoint\_service\_name) | ClickHouse private endpoint 'Service name' (ends in .azure.privatelinkservice). | `string` | `""` | no |
| <a name="input_clickhouse_region"></a> [clickhouse\_region](#input\_clickhouse\_region) | ClickHouse region (eastus2, westus3, etc). | `string` | `""` | no |
| <a name="input_cluster_sku_tier"></a> [cluster\_sku\_tier](#input\_cluster\_sku\_tier) | The Azure AKS SKU Tier to use for this cluster (https://learn.microsoft.com/en-us/azure/aks/free-standard-pricing-tiers) | `string` | `"Free"` | no |
| <a name="input_controller_image_tag"></a> [controller\_image\_tag](#input\_controller\_image\_tag) | Tag of the controller image to deploy | `string` | `"1.14.0"` | no |
| <a name="input_create_private_link"></a> [create\_private\_link](#input\_create\_private\_link) | Use for the azure private link. | `bool` | `false` | no |
| <a name="input_database_availability_mode"></a> [database\_availability\_mode](#input\_database\_availability\_mode) | n/a | `string` | `"SameZone"` | no |
| <a name="input_database_sku_name"></a> [database\_sku\_name](#input\_database\_sku\_name) | Specifies the SKU Name for this MySQL Server. Defaults to null and value from deployment-size.tf is used | `string` | `null` | no |
| <a name="input_database_version"></a> [database\_version](#input\_database\_version) | Version for MySQL | `string` | `"5.7"` | no |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | If the instance should have deletion protection enabled. The database / Bucket can't be deleted when this value is set to `true`. | `bool` | `true` | no |
| <a name="input_disable_storage_vault_key_id"></a> [disable\_storage\_vault\_key\_id](#input\_disable\_storage\_vault\_key\_id) | Flag to disable the `customer_managed_key` block, the properties 'encryption.identity, encryption.keyvaultproperties' cannot be updated in a single operation. | `bool` | `false` | no |
| <a name="input_domain_name"></a> [domain\_name](#input\_domain\_name) | Domain for accessing the Weights & Biases UI. | `string` | `null` | no |
| <a name="input_enable_database_vault_key"></a> [enable\_database\_vault\_key](#input\_enable\_database\_vault\_key) | Flag to enable managed key encryption for the database. Once enabled, cannot be disabled. | `bool` | `false` | no |
| <a name="input_enable_helm_release"></a> [enable\_helm\_release](#input\_enable\_helm\_release) | Enable or disable applying and releasing Helm chart | `bool` | `true` | no |
| <a name="input_enable_storage_vault_key"></a> [enable\_storage\_vault\_key](#input\_enable\_storage\_vault\_key) | Flag to enable managed key encryption for the storage account. | `bool` | `false` | no |
| <a name="input_external_bucket"></a> [external\_bucket](#input\_external\_bucket) | config an external bucket | `any` | `null` | no |
| <a name="input_kubernetes_cluster_oidc_issuer_url"></a> [kubernetes\_cluster\_oidc\_issuer\_url](#input\_kubernetes\_cluster\_oidc\_issuer\_url) | OIDC issuer URL for the Kubernetes cluster. Can be determined using `kubectl get --raw /.well-known/openid-configuration` | `string` | `""` | no |
| <a name="input_kubernetes_instance_type"></a> [kubernetes\_instance\_type](#input\_kubernetes\_instance\_type) | Instance type for primary node group. Defaults to null and value from deployment-size.tf is used | `string` | `null` | no |
| <a name="input_kubernetes_max_node_per_az"></a> [kubernetes\_max\_node\_per\_az](#input\_kubernetes\_max\_node\_per\_az) | Maximum number of nodes for the AKS cluster. Defaults to null and value from deployment-size.tf is used | `number` | `null` | no |
| <a name="input_kubernetes_min_node_per_az"></a> [kubernetes\_min\_node\_per\_az](#input\_kubernetes\_min\_node\_per\_az) | Minimum number of nodes for the AKS cluster. Defaults to null and value from deployment-size.tf is used | `number` | `null` | no |
| <a name="input_license"></a> [license](#input\_license) | Your wandb/local license | `string` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | n/a | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | String used for prefix resources. | `string` | n/a | yes |
| <a name="input_node_max_pods"></a> [node\_max\_pods](#input\_node\_max\_pods) | Maximum number of pods per node | `number` | `30` | no |
| <a name="input_node_pool_num_zones"></a> [node\_pool\_num\_zones](#input\_node\_pool\_num\_zones) | Number of availability zones to use for the node pool when node\_pool\_zones is not set. If neither are set, 3 zones will be used | `number` | `2` | no |
| <a name="input_node_pool_zones"></a> [node\_pool\_zones](#input\_node\_pool\_zones) | Availability zones for the node pool | `list(string)` | `null` | no |
| <a name="input_operator_chart_version"></a> [operator\_chart\_version](#input\_operator\_chart\_version) | Version of the operator chart to deploy | `string` | `"1.3.4"` | no |
| <a name="input_other_wandb_env"></a> [other\_wandb\_env](#input\_other\_wandb\_env) | Extra environment variables for W&B | `map(any)` | `{}` | no |
| <a name="input_parquet_wandb_env"></a> [parquet\_wandb\_env](#input\_parquet\_wandb\_env) | Extra environment variables for W&B | `map(string)` | `{}` | no |
| <a name="input_redis_capacity"></a> [redis\_capacity](#input\_redis\_capacity) | Number indicating size of an redis instance. Defaults to null and value from deployment-size.tf is used | `number` | `null` | no |
| <a name="input_size"></a> [size](#input\_size) | Deployment size | `string` | `"small"` | no |
| <a name="input_ssl"></a> [ssl](#input\_ssl) | Enable SSL certificate | `bool` | `true` | no |
| <a name="input_storage_account"></a> [storage\_account](#input\_storage\_account) | Azure storage account name | `string` | `""` | no |
| <a name="input_storage_key"></a> [storage\_key](#input\_storage\_key) | Azure primary storage access key | `string` | `""` | no |
| <a name="input_subdomain"></a> [subdomain](#input\_subdomain) | Subdomain for accessing the Weights & Biases UI. Default creates record at Route53 Route. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags for resource | `map(string)` | `{}` | no |
| <a name="input_use_internal_queue"></a> [use\_internal\_queue](#input\_use\_internal\_queue) | Uses an internal redis queue instead of using azure queue. | `bool` | `false` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_address"></a> [address](#output\_address) | n/a |
| <a name="output_aks_max_node_count"></a> [aks\_max\_node\_count](#output\_aks\_max\_node\_count) | n/a |
| <a name="output_aks_min_node_count"></a> [aks\_min\_node\_count](#output\_aks\_min\_node\_count) | n/a |
| <a name="output_aks_node_instance_type"></a> [aks\_node\_instance\_type](#output\_aks\_node\_instance\_type) | n/a |
| <a name="output_client_id"></a> [client\_id](#output\_client\_id) | n/a |
| <a name="output_cluster_ca_certificate"></a> [cluster\_ca\_certificate](#output\_cluster\_ca\_certificate) | n/a |
| <a name="output_cluster_client_certificate"></a> [cluster\_client\_certificate](#output\_cluster\_client\_certificate) | n/a |
| <a name="output_cluster_client_key"></a> [cluster\_client\_key](#output\_cluster\_client\_key) | n/a |
| <a name="output_cluster_host"></a> [cluster\_host](#output\_cluster\_host) | n/a |
| <a name="output_database_instance_type"></a> [database\_instance\_type](#output\_database\_instance\_type) | n/a |
| <a name="output_fqdn"></a> [fqdn](#output\_fqdn) | The FQDN to the W&B application |
| <a name="output_oidc_issuer_url"></a> [oidc\_issuer\_url](#output\_oidc\_issuer\_url) | n/a |
| <a name="output_private_link_resource_id"></a> [private\_link\_resource\_id](#output\_private\_link\_resource\_id) | n/a |
| <a name="output_private_link_sub_resource_name"></a> [private\_link\_sub\_resource\_name](#output\_private\_link\_sub\_resource\_name) | n/a |
| <a name="output_standardized_size"></a> [standardized\_size](#output\_standardized\_size) | n/a |
| <a name="output_tenant_id"></a> [tenant\_id](#output\_tenant\_id) | n/a |
| <a name="output_url"></a> [url](#output\_url) | The URL to the W&B application |
<!-- END_TF_DOCS -->

## Upgrading from 3.x to 4.x

3.0.0 introduced autoscaling to the AKS cluster and made the `size` variable the preferred way to set the cluster size.
Previously, unless the `size` variable was set explicitly, there were default values for the following variables:
- `kubernetes_instance_type`
- `kubernetes_node_count`
- `redis_capacity`
- `database_sku_name`

The `size` variable is now defaulted to `small`, and the following values to can be used to partially override the values
set by the `size` variable:
- `kubernetes_instance_type`
- `kubernetes_min_node_per_az`
- `kubernetes_max_node_per_az`
- `redis_capacity`
- `database_sku_name`

For more information on the available sizes, see the [Cluster Sizing](#cluster-sizing) section.

If having the cluster scale nodes in and out is not desired, the `kubernetes_min_node_per_az` and 
`kubernetes_max_node_per_az` can be set to the same value to prevent the cluster from scaling.

### Upgrading from 2.x to 3.x

When upgrading from 2.x to 3.x, the following changes are required:

1. Add the `azapi` provider to the `required_providers` block:

```hcl
terraform {
  required_providers {
    azapi = {
      source  = "azure/azapi"
      version = "~> 1.0"
    }
  }
}
```

2. Add the `azapi` provider to the `provider` block:

```hcl
provider "azapi" {
    # azapi provider configuration should be the same as azurerm provider configuration
}
```

