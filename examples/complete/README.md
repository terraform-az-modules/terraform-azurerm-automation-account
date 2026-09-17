# Complete example

This example creates a resource group with the
[`terraform-azurerm-resource-group`](https://github.com/terraform-az-modules/terraform-azurerm-resource-group)
module pinned to `v1.0.4`, then calls the root module once. It actively exercises
account security, identities, optional CMK encryption, a custom connection type
and connection, a runbook and schedule, all variable types, and a webhook.

It also creates an Ubuntu `Standard_B2s` VM (the smallest B-series size that
meets the Hybrid Worker minimum of 2 cores and 4 GiB RAM) with the
[`terraform-azurerm-virtual-machine`](https://github.com/terraform-az-modules/terraform-azurerm-virtual-machine)
module pinned to `v1.2.0`. The VM has a system-assigned identity and is onboarded
as a supported extension-based Linux Hybrid Runbook Worker. A public IP provides
the outbound HTTPS connectivity required by the Hybrid Worker extension; no
inbound NSG rule is created. Public network access is enabled on the Automation
Account for this smoke test; production deployments can disable it after adding
an Automation private endpoint and the required private DNS configuration.

Provide `resource_group_name`, `location`, and `automation_account_name`. When `key_vault_key_id` is set, provide exactly one value in `user_assigned_identity_ids`; that identity must have permission to use the Key Vault key.

```bash
terraform init
terraform plan \
  -var='resource_group_name=rg-example' \
  -var='location=West Europe' \
  -var='automation_account_name=aa-example-001'
```

If the configured resource group already exists, import it before applying:

```bash
terraform import 'module.resource_group.azurerm_resource_group.default[0]' \
  /subscriptions/<subscription-id>/resourceGroups/<resource-group-name>
```

The bottom of `example.tf` also documents the module's external-dependency
features: certificates and certificate connections, Hybrid Workers, legacy and
PowerShell modules, Python packages, runtime environments, DSC, source control,
and watchers. They are disabled by default with `enable_external_features =
false`, so placeholder values are never sent to Azure. Replace every placeholder
with a valid value before enabling them. Never commit certificate material,
passwords, or source-control tokens to version control.
