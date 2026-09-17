<!-- This file is generated from README.yaml. Keep both files aligned when documentation tooling is unavailable. -->

# Terraform Azure Automation Account

Reusable Terraform module for creating one Azure Automation Account and any optional Automation resources associated with it. Every child collection defaults to an empty map, so callers enable only the capabilities they need in dev, QA, stage, or production.

## Usage

```hcl
module "automation_account" {
  source = "terraform-az-modules/automation-account/azurerm"

  name                = "aa-app-prod-001"
  resource_group_name = "rg-app-prod"
  location            = "West Europe"

  identity = {
    type = "SystemAssigned"
  }

  local_authentication_enabled  = false
  public_network_access_enabled = false

  tags = {
    environment = "prod"
    managed-by  = "terraform"
  }
}
```

## Supported resources

| Input | AzureRM resource |
|------|------------------|
| Account settings | `azurerm_automation_account` |
| `certificates` | `azurerm_automation_certificate` |
| `connections` | `azurerm_automation_connection` |
| `connection_certificates` | `azurerm_automation_connection_certificate` |
| `connection_classic_certificates` | `azurerm_automation_connection_classic_certificate` |
| `connection_service_principals` | `azurerm_automation_connection_service_principal` |
| `connection_types` | `azurerm_automation_connection_type` |
| `credentials` | `azurerm_automation_credential` |
| `dsc_configurations` | `azurerm_automation_dsc_configuration` |
| `dsc_node_configurations` | `azurerm_automation_dsc_nodeconfiguration` |
| `hybrid_runbook_workers` | `azurerm_automation_hybrid_runbook_worker` |
| `hybrid_runbook_worker_groups` | `azurerm_automation_hybrid_runbook_worker_group` |
| `hybrid_runbook_worker_extensions` | `azurerm_virtual_machine_extension` |
| `job_schedules` | `azurerm_automation_job_schedule` |
| `modules` | `azurerm_automation_module` |
| `powershell72_modules` | `azurerm_automation_powershell72_module` |
| `python3_packages` | `azurerm_automation_python3_package` |
| `runbooks` | `azurerm_automation_runbook` |
| `runtime_environments` | `azurerm_automation_runtime_environment` |
| `runtime_environment_packages` | `azurerm_automation_runtime_environment_package` |
| `schedules` | `azurerm_automation_schedule` |
| `source_controls` | `azurerm_automation_source_control` |
| `bool_variables` | `azurerm_automation_variable_bool` |
| `datetime_variables` | `azurerm_automation_variable_datetime` |
| `int_variables` | `azurerm_automation_variable_int` |
| `object_variables` | `azurerm_automation_variable_object` |
| `string_variables` | `azurerm_automation_variable_string` |
| `watchers` | `azurerm_automation_watcher` |
| `webhooks` | `azurerm_automation_webhook` |

## Examples

| Example | Module call |
|---------|-------------|
| [`basic`](./examples/basic) | Account, system-assigned identity, security controls, and tags |
| [`runbook`](./examples/runbook) | Runbook, schedule, job schedule, webhook, and variable |
| [`dsc`](./examples/dsc) | DSC configuration and node configuration |
| [`runtime-environment`](./examples/runtime-environment) | Runtime environment, package, and runtime-linked runbook |
| [`complete`](./examples/complete) | Account security and the remaining Automation child-resource families |

All examples call `source = "../.."`; none defines a separate child module.

## Requirements

| Name | Version |
|------|---------|
| Terraform | >= 1.6.6 |
| azurerm | >= 5.4.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | Automation Account name. | `string` | `"automation-account"` | no |
| resource_group_name | Existing resource group name. | `string` | `"rg-automation-example"` | no |
| location | Azure region. | `string` | `"East US"` | no |
| sku_name | Automation Account SKU (`Basic` or `Free`). | `string` | `"Basic"` | no |
| identity | Managed identity type and user-assigned identity IDs. | `object` | `null` | no |
| local_authentication_enabled | Whether non-Azure AD authentication is enabled. | `bool` | `true` | no |
| public_network_access_enabled | Whether public network access is enabled. | `bool` | `true` | no |
| encryption | Key Vault key ID and optional user-assigned identity ID for CMK encryption. | `object` | `null` | no |
| tags | Resource tags. | `map(string)` | `{}` | no |
| timeouts | Create, read, update, and delete durations. | `object` | provider defaults | no |

All child-resource inputs are strongly typed `map(object(...))` values and default to `{}`. See [variables.tf](./variables.tf) for their complete schemas and the examples for practical configurations.

The root inputs include non-secret development defaults to prevent interactive Terraform prompts. Override `name`, `resource_group_name`, and `location` for real deployments using module arguments or environment-specific `.tfvars` files. Advanced features in the complete example that require secrets, external artifacts, or existing infrastructure are documented as commented opt-in blocks.

Supported identity types are `SystemAssigned`, `UserAssigned`, and `SystemAssigned, UserAssigned`. A user-assigned identity used for encryption must also appear in `identity.identity_ids` and must have the required Key Vault permissions.

## Outputs

The module exports account attributes, a `resource_ids` object grouped by child-resource type, sensitive DSC access keys, and sensitive webhook URIs.

## License

Apache 2.0. See [LICENSE](./LICENSE).
