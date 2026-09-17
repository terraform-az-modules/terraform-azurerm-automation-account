##-----------------------------------------------------------------------------
## Resources
##-----------------------------------------------------------------------------
resource "azurerm_automation_account" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku_name                      = var.sku_name
  local_authentication_enabled  = var.local_authentication_enabled
  public_network_access_enabled = var.public_network_access_enabled
  tags                          = var.tags

  dynamic "identity" {
    for_each = var.identity == null ? [] : [var.identity]
    content {
      type         = identity.value.type
      identity_ids = length(local.user_assigned_identity_ids) == 0 ? null : local.user_assigned_identity_ids
    }
  }

  dynamic "encryption" {
    for_each = var.encryption == null ? [] : [var.encryption]
    content {
      key_vault_key_id          = encryption.value.key_vault_key_id
      user_assigned_identity_id = encryption.value.user_assigned_identity_id
    }
  }

  timeouts {
    create = var.timeouts.create
    read   = var.timeouts.read
    update = var.timeouts.update
    delete = var.timeouts.delete
  }

  lifecycle {
    precondition {
      condition = var.encryption == null || var.encryption.user_assigned_identity_id == null ? true : (
        var.identity != null && contains(local.user_assigned_identity_ids, var.encryption.user_assigned_identity_id)
      )
      error_message = "The encryption user_assigned_identity_id must also be assigned through identity.identity_ids."
    }
  }
}

##-----------------------------------------------------------------------------
## Automation Account child resources
##-----------------------------------------------------------------------------
resource "azurerm_automation_certificate" "this" {
  for_each = toset(keys(nonsensitive(var.certificates)))

  name                    = var.certificates[each.key].name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  base64                  = var.certificates[each.key].base64
  description             = var.certificates[each.key].description
  exportable              = var.certificates[each.key].exportable

  timeouts {
    create = var.certificates[each.key].timeouts.create
    read   = var.certificates[each.key].timeouts.read
    update = var.certificates[each.key].timeouts.update
    delete = var.certificates[each.key].timeouts.delete
  }
}

resource "azurerm_automation_connection_type" "this" {
  for_each = var.connection_types

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  is_global               = each.value.is_global

  dynamic "field" {
    for_each = each.value.fields
    content {
      name         = field.value.name
      type         = field.value.type
      is_encrypted = field.value.is_encrypted
      is_optional  = field.value.is_optional
    }
  }

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_connection" "this" {
  for_each = toset(keys(nonsensitive(var.connections)))

  name                    = var.connections[each.key].name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  type                    = var.connections[each.key].connection_type_key == null ? var.connections[each.key].type : azurerm_automation_connection_type.this[var.connections[each.key].connection_type_key].name
  values                  = var.connections[each.key].values
  description             = var.connections[each.key].description

  timeouts {
    create = var.connections[each.key].timeouts.create
    read   = var.connections[each.key].timeouts.read
    update = var.connections[each.key].timeouts.update
    delete = var.connections[each.key].timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = (var.connections[each.key].type == null) != (var.connections[each.key].connection_type_key == null)
      error_message = "Each connection must set exactly one of type or connection_type_key."
    }
  }
}

resource "azurerm_automation_connection_certificate" "this" {
  for_each = var.connection_certificates

  name                        = each.value.name
  resource_group_name         = azurerm_automation_account.this.resource_group_name
  automation_account_name     = azurerm_automation_account.this.name
  automation_certificate_name = azurerm_automation_certificate.this[each.value.automation_certificate_key].name
  subscription_id             = each.value.subscription_id
  description                 = each.value.description

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_connection_classic_certificate" "this" {
  for_each = var.connection_classic_certificates

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  certificate_asset_name  = azurerm_automation_certificate.this[each.value.certificate_asset_key].name
  subscription_id         = each.value.subscription_id
  subscription_name       = each.value.subscription_name
  description             = each.value.description

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_connection_service_principal" "this" {
  for_each = var.connection_service_principals

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  application_id          = each.value.application_id
  certificate_thumbprint  = each.value.certificate_key == null ? each.value.certificate_thumbprint : azurerm_automation_certificate.this[each.value.certificate_key].thumbprint
  subscription_id         = each.value.subscription_id
  tenant_id               = each.value.tenant_id
  description             = each.value.description

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = (each.value.certificate_thumbprint == null) != (each.value.certificate_key == null)
      error_message = "Each service principal connection must set exactly one of certificate_thumbprint or certificate_key."
    }
  }
}

resource "azurerm_automation_credential" "this" {
  for_each = toset(keys(nonsensitive(var.credentials)))

  name                    = var.credentials[each.key].name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  username                = var.credentials[each.key].username
  password                = var.credentials[each.key].password
  description             = var.credentials[each.key].description

  timeouts {
    create = var.credentials[each.key].timeouts.create
    read   = var.credentials[each.key].timeouts.read
    update = var.credentials[each.key].timeouts.update
    delete = var.credentials[each.key].timeouts.delete
  }
}

resource "azurerm_automation_dsc_configuration" "this" {
  for_each = var.dsc_configurations

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  location                = azurerm_automation_account.this.location
  content_embedded        = each.value.content_embedded
  description             = each.value.description
  log_verbose             = each.value.log_verbose
  tags                    = merge(var.tags, each.value.tags)

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_dsc_nodeconfiguration" "this" {
  for_each = var.dsc_node_configurations

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  content_embedded        = each.value.content_embedded

  depends_on = [azurerm_automation_dsc_configuration.this]

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = try(each.value.dsc_configuration_key, null) == null || contains(keys(var.dsc_configurations), try(each.value.dsc_configuration_key, null))
      error_message = "dsc_configuration_key must reference an entry in dsc_configurations."
    }
  }
}

resource "azurerm_automation_hybrid_runbook_worker_group" "this" {
  for_each = var.hybrid_runbook_worker_groups

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  credential_name         = each.value.credential_key == null ? each.value.credential_name : azurerm_automation_credential.this[each.value.credential_key].name

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = !(each.value.credential_key != null && each.value.credential_name != null)
      error_message = "Set at most one of credential_key or credential_name for a Hybrid Runbook Worker group."
    }
  }
}

resource "azurerm_automation_hybrid_runbook_worker" "this" {
  for_each = var.hybrid_runbook_workers

  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  worker_group_name       = azurerm_automation_hybrid_runbook_worker_group.this[each.value.worker_group_key].name
  worker_id               = each.value.worker_id
  vm_resource_id          = each.value.vm_resource_id

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    delete = each.value.timeouts.delete
  }

  lifecycle {
    # Azure returns this resource ID fully lowercased. Resource IDs are
    # case-insensitive, so suppress the resulting perpetual replacement.
    ignore_changes = [vm_resource_id]
  }
}

# Installs the supported extension-based (V2) Hybrid Worker on an Azure VM.
# The VM must have a system-assigned managed identity and outbound HTTPS access
# to the Azure Automation endpoints required for its region.
resource "azurerm_virtual_machine_extension" "hybrid_worker" {
  for_each = var.hybrid_runbook_worker_extensions

  name = each.value.name
  # Use the caller-supplied VM ID rather than the worker API response. Azure
  # normalizes the response to lowercase, but AzureRM's VM ID parser expects
  # case-sensitive resourceGroups/Microsoft.Compute/virtualMachines segments.
  virtual_machine_id         = var.hybrid_runbook_workers[each.value.hybrid_worker_key].vm_resource_id
  publisher                  = "Microsoft.Azure.Automation.HybridWorker"
  type                       = "HybridWorkerFor${each.value.os_type}"
  type_handler_version       = each.value.type_handler_version
  auto_upgrade_minor_version = each.value.auto_upgrade_minor
  automatic_upgrade_enabled  = each.value.automatic_upgrade
  settings = jsonencode(merge(each.value.settings, {
    AutomationAccountURL = azurerm_automation_account.this.hybrid_service_url
  }))
  protected_settings = length(keys(each.value.protected_settings)) == 0 ? null : jsonencode(each.value.protected_settings)
  tags               = merge(var.tags, each.value.tags)

  depends_on = [azurerm_automation_hybrid_runbook_worker.this]

  lifecycle {
    precondition {
      condition     = contains(keys(var.hybrid_runbook_workers), each.value.hybrid_worker_key)
      error_message = "hybrid_worker_key must reference an entry in hybrid_runbook_workers."
    }
  }
}

resource "azurerm_automation_module" "this" {
  for_each = var.modules

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name

  module_link {
    uri = each.value.module_link.uri
    dynamic "hash" {
      for_each = each.value.module_link.hash == null ? [] : [each.value.module_link.hash]
      content {
        algorithm = hash.value.algorithm
        value     = hash.value.value
      }
    }
  }

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_powershell72_module" "this" {
  for_each = var.powershell72_modules

  name                  = each.value.name
  automation_account_id = azurerm_automation_account.this.id
  tags                  = merge(var.tags, each.value.tags)

  module_link {
    uri = each.value.module_link.uri
    dynamic "hash" {
      for_each = each.value.module_link.hash == null ? [] : [each.value.module_link.hash]
      content {
        algorithm = hash.value.algorithm
        value     = hash.value.value
      }
    }
  }

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_python3_package" "this" {
  for_each = var.python3_packages

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  content_uri             = each.value.content_uri
  content_version         = each.value.content_version
  hash_algorithm          = each.value.hash_algorithm
  hash_value              = each.value.hash_value
  tags                    = merge(var.tags, each.value.tags)

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_runtime_environment" "this" {
  for_each = var.runtime_environments

  name                     = each.value.name
  automation_account_id    = azurerm_automation_account.this.id
  location                 = azurerm_automation_account.this.location
  runtime_language         = each.value.runtime_language
  runtime_version          = each.value.runtime_version
  runtime_default_packages = each.value.runtime_default_packages
  description              = each.value.description
  tags                     = merge(var.tags, each.value.tags)

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_runtime_environment_package" "this" {
  for_each = var.runtime_environment_packages

  name                              = each.value.name
  automation_runtime_environment_id = azurerm_automation_runtime_environment.this[each.value.runtime_environment_key].id
  content_uri                       = each.value.content_uri
  content_version                   = each.value.content_version
  hash_algorithm                    = each.value.hash_algorithm
  hash_value                        = each.value.hash_value

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_runbook" "this" {
  for_each = var.runbooks

  name                     = each.value.name
  resource_group_name      = azurerm_automation_account.this.resource_group_name
  automation_account_name  = azurerm_automation_account.this.name
  location                 = azurerm_automation_account.this.location
  runbook_type             = each.value.runbook_type
  log_progress             = each.value.log_progress
  log_verbose              = each.value.log_verbose
  content                  = each.value.content
  description              = each.value.description
  log_activity_trace_level = each.value.log_activity_trace_level
  runtime_environment_name = each.value.runtime_environment_key == null ? each.value.runtime_environment_name : azurerm_automation_runtime_environment.this[each.value.runtime_environment_key].name
  tags                     = merge(var.tags, each.value.tags)

  dynamic "draft" {
    for_each = each.value.draft == null ? [] : [each.value.draft]
    content {
      edit_mode_enabled = draft.value.edit_mode_enabled
      output_types      = draft.value.output_types

      dynamic "content_link" {
        for_each = draft.value.content_link == null ? [] : [draft.value.content_link]
        content {
          uri     = content_link.value.uri
          version = content_link.value.version
          dynamic "hash" {
            for_each = content_link.value.hash == null ? [] : [content_link.value.hash]
            content {
              algorithm = hash.value.algorithm
              value     = hash.value.value
            }
          }
        }
      }

      dynamic "parameters" {
        for_each = draft.value.parameters
        content {
          key           = parameters.value.key
          type          = parameters.value.type
          default_value = parameters.value.default_value
          mandatory     = parameters.value.mandatory
          position      = parameters.value.position
        }
      }
    }
  }

  dynamic "publish_content_link" {
    for_each = each.value.publish_content_link == null ? [] : [each.value.publish_content_link]
    content {
      uri     = publish_content_link.value.uri
      version = publish_content_link.value.version
      dynamic "hash" {
        for_each = publish_content_link.value.hash == null ? [] : [publish_content_link.value.hash]
        content {
          algorithm = hash.value.algorithm
          value     = hash.value.value
        }
      }
    }
  }

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = !(each.value.runtime_environment_key != null && each.value.runtime_environment_name != null)
      error_message = "Set at most one of runtime_environment_key or runtime_environment_name for a runbook."
    }
  }
}

resource "azurerm_automation_schedule" "this" {
  for_each = var.schedules

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  frequency               = each.value.frequency
  description             = each.value.description
  interval                = each.value.interval
  start_time              = each.value.start_time
  expiry_time             = each.value.expiry_time
  timezone                = each.value.timezone
  week_days               = each.value.week_days
  month_days              = each.value.month_days

  dynamic "monthly_occurrence" {
    for_each = each.value.monthly_occurrence == null ? [] : [each.value.monthly_occurrence]
    content {
      day        = monthly_occurrence.value.day
      occurrence = monthly_occurrence.value.occurrence
    }
  }

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_job_schedule" "this" {
  for_each = var.job_schedules

  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  runbook_name            = azurerm_automation_runbook.this[each.value.runbook_key].name
  schedule_name           = azurerm_automation_schedule.this[each.value.schedule_key].name
  job_schedule_id         = coalesce(each.value.job_schedule_id, each.key)
  parameters              = each.value.parameters
  run_on                  = each.value.run_on_worker_group_key == null ? each.value.run_on : azurerm_automation_hybrid_runbook_worker_group.this[each.value.run_on_worker_group_key].name

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    delete = each.value.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = !(each.value.run_on != null && each.value.run_on_worker_group_key != null)
      error_message = "Set at most one of run_on or run_on_worker_group_key for a job schedule."
    }
  }
}

resource "azurerm_automation_source_control" "this" {
  for_each = toset(keys(nonsensitive(var.source_controls)))

  name                    = var.source_controls[each.key].name
  automation_account_id   = azurerm_automation_account.this.id
  folder_path             = var.source_controls[each.key].folder_path
  repository_url          = var.source_controls[each.key].repository_url
  source_control_type     = var.source_controls[each.key].source_control_type
  automatic_sync          = var.source_controls[each.key].automatic_sync
  branch                  = var.source_controls[each.key].branch
  description             = var.source_controls[each.key].description
  publish_runbook_enabled = var.source_controls[each.key].publish_runbook_enabled

  security {
    token         = var.source_controls[each.key].security.token
    token_type    = var.source_controls[each.key].security.token_type
    refresh_token = var.source_controls[each.key].security.refresh_token
  }

  timeouts {
    create = var.source_controls[each.key].timeouts.create
    read   = var.source_controls[each.key].timeouts.read
    update = var.source_controls[each.key].timeouts.update
    delete = var.source_controls[each.key].timeouts.delete
  }
}

resource "azurerm_automation_variable_bool" "this" {
  for_each = var.bool_variables

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
  description             = each.value.description

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_variable_datetime" "this" {
  for_each = var.datetime_variables

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
  description             = each.value.description

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_variable_int" "this" {
  for_each = var.int_variables

  name                    = each.value.name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = each.value.value
  encrypted               = each.value.encrypted
  description             = each.value.description

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }
}

resource "azurerm_automation_variable_object" "this" {
  for_each = toset(keys(nonsensitive(var.object_variables)))

  name                    = var.object_variables[each.key].name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = var.object_variables[each.key].value
  encrypted               = var.object_variables[each.key].encrypted
  description             = var.object_variables[each.key].description

  timeouts {
    create = var.object_variables[each.key].timeouts.create
    read   = var.object_variables[each.key].timeouts.read
    update = var.object_variables[each.key].timeouts.update
    delete = var.object_variables[each.key].timeouts.delete
  }
}

resource "azurerm_automation_variable_string" "this" {
  for_each = toset(keys(nonsensitive(var.string_variables)))

  name                    = var.string_variables[each.key].name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  value                   = var.string_variables[each.key].value
  encrypted               = var.string_variables[each.key].encrypted
  description             = var.string_variables[each.key].description

  timeouts {
    create = var.string_variables[each.key].timeouts.create
    read   = var.string_variables[each.key].timeouts.read
    update = var.string_variables[each.key].timeouts.update
    delete = var.string_variables[each.key].timeouts.delete
  }
}

resource "azurerm_automation_watcher" "this" {
  for_each = var.watchers

  name                           = each.value.name
  automation_account_id          = azurerm_automation_account.this.id
  location                       = azurerm_automation_account.this.location
  execution_frequency_in_seconds = each.value.execution_frequency_in_seconds
  script_name                    = each.value.script_runbook_key == null ? each.value.script_name : azurerm_automation_runbook.this[each.value.script_runbook_key].name
  script_run_on                  = each.value.script_run_on_worker_group_key == null ? each.value.script_run_on : azurerm_automation_hybrid_runbook_worker_group.this[each.value.script_run_on_worker_group_key].name
  script_parameters              = each.value.script_parameters
  description                    = each.value.description
  etag                           = each.value.etag
  tags                           = merge(var.tags, each.value.tags)

  timeouts {
    create = each.value.timeouts.create
    read   = each.value.timeouts.read
    update = each.value.timeouts.update
    delete = each.value.timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = (each.value.script_name == null) != (each.value.script_runbook_key == null)
      error_message = "Each watcher must set exactly one of script_name or script_runbook_key."
    }
    precondition {
      condition     = (each.value.script_run_on == null) != (each.value.script_run_on_worker_group_key == null)
      error_message = "Each watcher must set exactly one of script_run_on or script_run_on_worker_group_key."
    }
  }
}

resource "azurerm_automation_webhook" "this" {
  for_each = toset(keys(nonsensitive(var.webhooks)))

  name                    = var.webhooks[each.key].name
  resource_group_name     = azurerm_automation_account.this.resource_group_name
  automation_account_name = azurerm_automation_account.this.name
  runbook_name            = azurerm_automation_runbook.this[var.webhooks[each.key].runbook_key].name
  expiry_time             = var.webhooks[each.key].expiry_time
  enabled                 = var.webhooks[each.key].enabled
  parameters              = var.webhooks[each.key].parameters
  run_on_worker_group     = var.webhooks[each.key].run_on_worker_group_key == null ? var.webhooks[each.key].run_on_worker_group : azurerm_automation_hybrid_runbook_worker_group.this[var.webhooks[each.key].run_on_worker_group_key].name

  timeouts {
    create = var.webhooks[each.key].timeouts.create
    read   = var.webhooks[each.key].timeouts.read
    update = var.webhooks[each.key].timeouts.update
    delete = var.webhooks[each.key].timeouts.delete
  }

  lifecycle {
    precondition {
      condition     = !(var.webhooks[each.key].run_on_worker_group_key != null && var.webhooks[each.key].run_on_worker_group != null)
      error_message = "Set at most one of run_on_worker_group_key or run_on_worker_group for a webhook."
    }
  }
}
