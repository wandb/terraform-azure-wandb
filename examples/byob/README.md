# Azure BYOB

## About

Weights & Biases can connect to a Azure Blob Storage Container created and owned by the customer. This is called BYOB (Bring your own bucket). More details (here)[https://docs.wandb.ai/guides/hosting/data-security/secure-storage-connector#provision-the-azure-blob-storage].

This example does not deploy a Weights & Biases instance. It deploys all required resources (Storage container and permissions) in the customer's account.

---

## Using Terraform

This example can be used to create the Azure Blob Storage container required when using the BYOB mode for Dedicated Cloud deployment.

1. Make sure you have Terraform installed
2. Make sure you have Azure CLI installed and configured
3. Clone this repository
4. Access the directory `examples/byob` and fix the options in the file `terraform.tfvars`

Once the configuration is done, just execute the Terraform following the example below:

```bash
terraform init
terraform apply -var-file=terraform.tfvars
```

At the end of execution you will have the following output:

```bash
blob_container = "rgnamestorage/wandb"
storage_key = <sensitive>
```

To retrieve the storage key, you can use the Azure CLI installed previously like the example below:

```bash
az storage account keys list --account-name <storage_account_name> --resource-group <resource_group_name> --query '[0].value' -o tsv
1111111111111122222222222333333333334444444555555555
```

This command will return the storage key. Ensure you handle the storage key securely.

### Customer Managed Key Encryption

The following section provides details on enabling Customer Managed Key (CMK) encryption for the Azure Blob Storage container which is disabled by default.

To configure Customer Managed Key encryption, ensure you are using the latest version of out terraform which has the following added to the `variables.tf` file:

- create_cmk
- disable_storage_vault_key_id
- tenant_id
- client_id

You need to obtain the `tenant_id` and `client_id` from the `https://${WANDB_BASE_URL}/console/settings/advanced/spec/active` at W&B for an already instantiated instance of a Weights & Biases managed deployment.

Set the follwoing new variabels to enable the CMK:

```ini terraform.tfvars
create_cmk = true

disable_storage_vault_key_id  = false

tenant_id = "<tenant_id>"
client_id = "<client_id>"
```

After updating your `terraform.tfvars` configuration, run the Terraform commands to apply the changes:

```bash
terraform init -upgrade
terraform apply -var-file=terraform.tfvars
```

Upon successful execution, you will receive the following output which needs to be set in the system connection settings `https://${WANDB_BASE_URL}/console/settings/system`

```bash
blob_container = "<storage_account_name>/wandb"
command_to_get_storage_key = "az storage account keys list --account-name <storage_account_name> --resource-group <resource_group_name> --query '[0].value' -o tsv"
storage_key = <sensitive>
storage_vault_key_id = "https://<key_vault_name>.vault.azure.net/keys/<key_name>/<key_version>"
```

Retrieve the storage key as shown above.

## Using Azure Portal

Please refer to the (public documentation)[https://docs.wandb.ai/guides/hosting/data-security/secure-storage-connector#provision-the-azure-blob-storage] on how to create all required resources manually.
