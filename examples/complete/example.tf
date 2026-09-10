provider "azurerm" {
  features {}
}

module "automation_account" {
  source = "../.."

  name                = var.automation_account_name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku_name            = "Basic"

  identity = length(var.user_assigned_identity_ids) == 0 ? {
    type         = "SystemAssigned"
    identity_ids = []
    } : {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = var.user_assigned_identity_ids
  }

  local_authentication_enabled  = false
  public_network_access_enabled = false

  encryption = var.key_vault_key_id == null ? null : {
    key_vault_key_id          = var.key_vault_key_id
    user_assigned_identity_id = one(var.user_assigned_identity_ids)
  }

  tags = {
    environment = "example"
    managed-by  = "terraform"
  }
  timeouts = {
    create = "45m"
    update = "45m"
  }

  certificates = {
    deployment = {
      name       = "deployment-certificate"
      base64     = var.certificate_base64
      exportable = false
    }
  }

  connection_types = {
    endpoint = {
      name = "EndpointConnection"
      fields = [{
        name = "Endpoint"
        type = "System.String"
      }]
    }
  }

  connections = {
    endpoint = {
      name                = "example-endpoint"
      connection_type_key = "endpoint"
      values              = { Endpoint = "https://management.azure.com" }
    }
  }

  connection_certificates = {
    azure = {
      name                       = "azure-certificate"
      automation_certificate_key = "deployment"
      subscription_id            = var.subscription_id
    }
  }

  connection_classic_certificates = {
    classic = {
      name                  = "azure-classic-certificate"
      certificate_asset_key = "deployment"
      subscription_id       = var.subscription_id
      subscription_name     = "example-subscription"
    }
  }

  connection_service_principals = {
    deployment = {
      name            = "deployment-service-principal"
      application_id  = var.application_id
      certificate_key = "deployment"
      subscription_id = var.subscription_id
      tenant_id       = var.tenant_id
    }
  }

  credentials = {
    worker = {
      name     = "worker-credential"
      username = "automation-worker"
      password = var.credential_password
    }
  }

  hybrid_runbook_worker_groups = {
    operations = {
      name           = "operations-workers"
      credential_key = "worker"
    }
  }

  hybrid_runbook_workers = {
    primary = {
      worker_group_key = "operations"
      worker_id        = var.worker_id
      vm_resource_id   = var.worker_vm_resource_id
    }
  }

  modules = {
    legacy = {
      name        = "Example.Legacy"
      module_link = { uri = var.module_content_uri }
    }
  }

  powershell72_modules = {
    modern = {
      name        = "Example.Modern"
      module_link = { uri = var.powershell_module_content_uri }
    }
  }

  python3_packages = {
    example = {
      name        = "example-package"
      content_uri = var.python_package_content_uri
    }
  }

  runbooks = {
    operations = {
      name         = "operations"
      runbook_type = "PowerShell"
      log_progress = true
      log_verbose  = true
      content      = "Write-Output 'operations'"
    }
  }

  schedules = {
    hourly = {
      name      = "hourly"
      frequency = "Hour"
      interval  = 1
      timezone  = "UTC"
    }
  }

  job_schedules = {
    "19267d3b-7a64-4f82-bc50-7c49b72a57e4" = {
      runbook_key             = "operations"
      schedule_key            = "hourly"
      run_on_worker_group_key = "operations"
    }
  }

  source_controls = {
    repository = {
      name                = "automation-repository"
      folder_path         = "/"
      repository_url      = var.source_control_repository_url
      source_control_type = "GitHub"
      branch              = "main"
      security = {
        token      = var.source_control_token
        token_type = "PersonalAccessToken"
      }
    }
  }

  bool_variables = {
    enabled = { name = "Enabled", value = true }
  }
  datetime_variables = {
    maintenance = { name = "MaintenanceWindow", value = "2030-01-01T00:00:00Z" }
  }
  int_variables = {
    retry_count = { name = "RetryCount", value = 3 }
  }
  object_variables = {
    settings = { name = "Settings", value = jsonencode({ mode = "safe" }) }
  }
  string_variables = {
    environment = { name = "Environment", value = "example" }
  }

  watchers = {
    operations = {
      name                           = "operations-watcher"
      execution_frequency_in_seconds = 60
      script_runbook_key             = "operations"
      script_run_on_worker_group_key = "operations"
    }
  }

  webhooks = {
    operations = {
      name                    = "operations-webhook"
      runbook_key             = "operations"
      expiry_time             = "2030-12-31T23:59:59Z"
      run_on_worker_group_key = "operations"
    }
  }
}
