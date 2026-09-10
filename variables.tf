##-----------------------------------------------------------------------------
## Variables
##-----------------------------------------------------------------------------
variable "name" {
  type        = string
  default     = "automation-account"
  description = "Name of the Azure Automation Account."
  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{4,48}[A-Za-z0-9]$", var.name))
    error_message = "The name must be 6-50 characters, start with a letter, end with a letter or number, and contain only letters, numbers, and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  default     = "rg-automation-example"
  description = "Name of the resource group in which to create the Automation Account."
  validation {
    condition     = length(trimspace(var.resource_group_name)) >= 1 && length(var.resource_group_name) <= 90
    error_message = "resource_group_name must contain between 1 and 90 characters."
  }
}

variable "location" {
  type        = string
  default     = "East US"
  description = "Azure region in which to create the Automation Account."
  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "sku_name" {
  type        = string
  default     = "Basic"
  description = "SKU of the Automation Account. Valid values are Basic and Free."
  validation {
    condition     = contains(["Basic", "Free"], var.sku_name)
    error_message = "sku_name must be either Basic or Free."
  }
}

variable "identity" {
  type = object({
    type         = string
    identity_ids = optional(set(string), [])
  })
  default     = null
  nullable    = true
  description = "Managed identity configuration. identity_ids is required for UserAssigned and combined identities."

  validation {
    condition = var.identity == null ? true : contains([
      "SystemAssigned", "UserAssigned", "SystemAssigned, UserAssigned"
    ], var.identity.type)
    error_message = "identity.type must be SystemAssigned, UserAssigned, or SystemAssigned, UserAssigned."
  }
  validation {
    condition = var.identity == null ? true : (
      var.identity.type == "SystemAssigned" ? length(var.identity.identity_ids) == 0 : length(var.identity.identity_ids) > 0
    )
    error_message = "identity_ids must be empty for SystemAssigned and non-empty for UserAssigned or combined identities."
  }
  validation {
    condition = var.identity == null ? true : alltrue([
      for id in var.identity.identity_ids : can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ManagedIdentity/userAssignedIdentities/[^/]+$", id))
    ])
    error_message = "Each identity_ids value must be a valid user-assigned managed identity resource ID."
  }
}

variable "local_authentication_enabled" {
  type        = bool
  default     = true
  description = "Whether non-Azure AD authentication is enabled."
}

variable "public_network_access_enabled" {
  type        = bool
  default     = true
  description = "Whether public network access is allowed for the Automation Account."
}

variable "encryption" {
  type = object({
    key_vault_key_id          = string
    user_assigned_identity_id = optional(string)
  })
  default     = null
  nullable    = true
  description = "Customer-managed key encryption configuration."

  validation {
    condition = var.encryption == null ? true : can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.KeyVault/vaults/[^/]+/keys/[^/]+(?:/[^/]+)?$", var.encryption.key_vault_key_id
    ))
    error_message = "encryption.key_vault_key_id must be a valid Key Vault key resource ID."
  }
  validation {
    condition = var.encryption == null || var.encryption.user_assigned_identity_id == null ? true : can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ManagedIdentity/userAssignedIdentities/[^/]+$", var.encryption.user_assigned_identity_id
    ))
    error_message = "encryption.user_assigned_identity_id must be a valid user-assigned managed identity resource ID."
  }
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to assign to the Automation Account."
}

variable "timeouts" {
  type = object({
    create = optional(string, "30m")
    read   = optional(string, "5m")
    update = optional(string, "30m")
    delete = optional(string, "30m")
  })
  default     = {}
  description = "Timeouts for create, read, update, and delete operations."
  validation {
    condition = alltrue([
      for timeout in [var.timeouts.create, var.timeouts.read, var.timeouts.update, var.timeouts.delete] : can(timeadd("2020-01-01T00:00:00Z", timeout))
    ])
    error_message = "Each timeout must be a valid Terraform duration such as 30m or 1h30m."
  }
}

##-----------------------------------------------------------------------------
## Automation Account child resource variables
##-----------------------------------------------------------------------------
variable "certificates" {
  type = map(object({
    name        = string
    base64      = string
    description = optional(string)
    exportable  = optional(bool, false)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  sensitive   = true
  description = "Automation certificates keyed by a stable Terraform key. Certificate base64 values are sensitive."
}

variable "connection_types" {
  type = map(object({
    name      = string
    is_global = optional(bool, false)
    fields = list(object({
      name         = string
      type         = string
      is_encrypted = optional(bool, false)
      is_optional  = optional(bool, false)
    }))
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Custom Automation connection types keyed by a stable Terraform key."
}

variable "connections" {
  type = map(object({
    name                = string
    type                = optional(string)
    connection_type_key = optional(string)
    values              = map(string)
    description         = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  sensitive   = true
  description = "Generic Automation connections. Set type or connection_type_key; values may contain secrets."
}

variable "connection_certificates" {
  type = map(object({
    name                       = string
    automation_certificate_key = string
    subscription_id            = string
    description                = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Azure certificate connections referencing entries in certificates."
}

variable "connection_classic_certificates" {
  type = map(object({
    name                  = string
    certificate_asset_key = string
    subscription_id       = string
    subscription_name     = string
    description           = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Classic certificate connections referencing entries in certificates."
}

variable "connection_service_principals" {
  type = map(object({
    name                   = string
    application_id         = string
    certificate_thumbprint = optional(string)
    certificate_key        = optional(string)
    subscription_id        = string
    tenant_id              = string
    description            = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Service principal connections keyed by a stable Terraform key."
}

variable "credentials" {
  type = map(object({
    name        = string
    username    = string
    password    = string
    description = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  sensitive   = true
  description = "Automation credentials keyed by a stable Terraform key. Passwords are sensitive."
}

variable "dsc_configurations" {
  type = map(object({
    name                  = string
    content_embedded      = string
    dsc_configuration_key = optional(string)
    description           = optional(string)
    log_verbose           = optional(bool, false)
    tags                  = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "DSC configurations keyed by a stable Terraform key."
}

variable "dsc_node_configurations" {
  type = map(object({
    name             = string
    content_embedded = string
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Compiled DSC node configurations keyed by a stable Terraform key."
}

variable "hybrid_runbook_worker_groups" {
  type = map(object({
    name            = string
    credential_key  = optional(string)
    credential_name = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Hybrid Runbook Worker groups. A credential may be referenced by module key or Azure name."
}

variable "hybrid_runbook_workers" {
  type = map(object({
    worker_group_key = string
    worker_id        = string
    vm_resource_id   = string
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Hybrid Runbook Workers referencing entries in hybrid_runbook_worker_groups."
}

variable "modules" {
  type = map(object({
    name = string
    module_link = object({
      uri = string
      hash = optional(object({
        algorithm = string
        value     = string
      }))
    })
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Legacy Automation modules keyed by a stable Terraform key."
}

variable "powershell72_modules" {
  type = map(object({
    name = string
    module_link = object({
      uri = string
      hash = optional(object({
        algorithm = string
        value     = string
      }))
    })
    tags = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "PowerShell 7.2 modules keyed by a stable Terraform key."
}

variable "python3_packages" {
  type = map(object({
    name            = string
    content_uri     = string
    content_version = optional(string)
    hash_algorithm  = optional(string)
    hash_value      = optional(string)
    tags            = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Python 3 packages keyed by a stable Terraform key."
}

variable "runtime_environments" {
  type = map(object({
    name                     = string
    runtime_language         = string
    runtime_version          = string
    runtime_default_packages = optional(map(string), {})
    description              = optional(string)
    tags                     = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Automation runtime environments keyed by a stable Terraform key."
}

variable "runtime_environment_packages" {
  type = map(object({
    name                    = string
    runtime_environment_key = string
    content_uri             = string
    content_version         = optional(string)
    hash_algorithm          = optional(string)
    hash_value              = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Runtime environment packages referencing entries in runtime_environments."
}

variable "runbooks" {
  type = map(object({
    name                     = string
    runbook_type             = string
    log_progress             = bool
    log_verbose              = bool
    content                  = optional(string)
    description              = optional(string)
    log_activity_trace_level = optional(number)
    runtime_environment_key  = optional(string)
    runtime_environment_name = optional(string)
    tags                     = optional(map(string), {})
    draft = optional(object({
      edit_mode_enabled = optional(bool)
      output_types      = optional(list(string))
      content_link = optional(object({
        uri     = string
        version = optional(string)
        hash = optional(object({
          algorithm = string
          value     = string
        }))
      }))
      parameters = optional(list(object({
        key           = string
        type          = string
        default_value = optional(string)
        mandatory     = optional(bool)
        position      = optional(number)
      })), [])
    }))
    publish_content_link = optional(object({
      uri     = string
      version = optional(string)
      hash = optional(object({
        algorithm = string
        value     = string
      }))
    }))
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Automation runbooks keyed by a stable Terraform key."
}

variable "schedules" {
  type = map(object({
    name        = string
    frequency   = string
    description = optional(string)
    interval    = optional(number)
    start_time  = optional(string)
    expiry_time = optional(string)
    timezone    = optional(string)
    week_days   = optional(set(string))
    month_days  = optional(set(number))
    monthly_occurrence = optional(object({
      day        = string
      occurrence = number
    }))
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Automation schedules keyed by a stable Terraform key."
}

variable "job_schedules" {
  type = map(object({
    runbook_key             = string
    schedule_key            = string
    parameters              = optional(map(string), {})
    run_on                  = optional(string)
    run_on_worker_group_key = optional(string)
    job_schedule_id         = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Associations between entries in runbooks and schedules. Map keys should be UUIDs unless job_schedule_id is set."
}

variable "source_controls" {
  type = map(object({
    name                    = string
    folder_path             = string
    repository_url          = string
    source_control_type     = string
    automatic_sync          = optional(bool, false)
    branch                  = optional(string)
    description             = optional(string)
    publish_runbook_enabled = optional(bool, true)
    security = object({
      token         = string
      token_type    = string
      refresh_token = optional(string)
    })
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  sensitive   = true
  description = "Automation source controls keyed by a stable Terraform key. Security tokens are sensitive."
}

variable "bool_variables" {
  type = map(object({
    name        = string
    value       = optional(bool)
    encrypted   = optional(bool, false)
    description = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Boolean Automation variables."
}

variable "datetime_variables" {
  type = map(object({
    name        = string
    value       = optional(string)
    encrypted   = optional(bool, false)
    description = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Datetime Automation variables."
}

variable "int_variables" {
  type = map(object({
    name        = string
    value       = optional(number)
    encrypted   = optional(bool, false)
    description = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Integer Automation variables."
}

variable "object_variables" {
  type = map(object({
    name        = string
    value       = optional(string)
    encrypted   = optional(bool, false)
    description = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  sensitive   = true
  description = "JSON-encoded object Automation variables. Values may be sensitive."
}

variable "string_variables" {
  type = map(object({
    name        = string
    value       = optional(string)
    encrypted   = optional(bool, false)
    description = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  sensitive   = true
  description = "String Automation variables. Values may be sensitive."
}

variable "watchers" {
  type = map(object({
    name                           = string
    execution_frequency_in_seconds = number
    script_run_on                  = optional(string)
    script_run_on_worker_group_key = optional(string)
    script_runbook_key             = optional(string)
    script_name                    = optional(string)
    script_parameters              = optional(map(string), {})
    description                    = optional(string)
    etag                           = optional(string)
    tags                           = optional(map(string), {})
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  description = "Automation watchers. Script can be referenced by runbook key or Azure name."
}

variable "webhooks" {
  type = map(object({
    name                    = string
    expiry_time             = string
    runbook_key             = string
    enabled                 = optional(bool, true)
    parameters              = optional(map(string), {})
    run_on_worker_group_key = optional(string)
    run_on_worker_group     = optional(string)
    timeouts = optional(object({
      create = optional(string)
      read   = optional(string)
      update = optional(string)
      delete = optional(string)
    }), {})
  }))
  default     = {}
  sensitive   = true
  description = "Automation webhooks referencing entries in runbooks and optionally worker groups."
}
