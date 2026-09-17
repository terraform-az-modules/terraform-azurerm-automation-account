provider "azurerm" {
  features {}
}

module "resource_group" {
  source      = "terraform-az-modules/resource-group/azurerm"
  version     = "1.0.4"
  name        = var.resource_group_name
  environment = "test"
  label_order = ["environment", "name", ]
  location    = var.location
}

# A small network dedicated to the extension-based Hybrid Worker VM.
resource "azurerm_virtual_network" "hybrid_worker" {
  name                = "vnet-automation-worker"
  address_space       = ["10.42.0.0/16"]
  location            = module.resource_group.resource_group_location
  resource_group_name = module.resource_group.resource_group_name
}

resource "azurerm_subnet" "hybrid_worker" {
  name                 = "snet-automation-worker"
  resource_group_name  = module.resource_group.resource_group_name
  virtual_network_name = azurerm_virtual_network.hybrid_worker.name
  address_prefixes     = ["10.42.1.0/24"]
}

module "hybrid_worker_vm" {
  source  = "terraform-az-modules/virtual-machine/azurerm"
  version = "1.2.0"

  name                = "automation-worker"
  environment         = "test"
  label_order         = ["environment", "name"]
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location

  is_vm_linux = true
  # Hybrid Worker V2 requires at least 2 CPU cores and 4 GiB of memory.
  # Standard_B2s is the smallest B-series size that satisfies both limits.
  vm_size                       = "Standard_B2s"
  computer_name                 = "automation-worker"
  admin_username                = "azureadmin"
  subnet_id                     = azurerm_subnet.hybrid_worker.id
  private_ip_address_allocation = "Dynamic"
  network_interface_sg_enabled  = false
  public_ip_enabled             = true
  diagnostic_setting_enable     = false

  image_publisher = "Canonical"
  image_offer     = "0001-com-ubuntu-server-jammy"
  image_sku       = "22_04-lts-gen2"
  image_version   = "latest"

  os_disk_storage_account_type = "Standard_LRS"
  disk_size_gb                 = 30
  enable_disk_encryption_set   = false
  enable_encryption_at_host    = false
  identity_enabled             = true
  vm_identity_type             = "SystemAssigned"
}

module "automation_account" {
  source = "../.."

  name                = var.automation_account_name
  resource_group_name = module.resource_group.resource_group_name
  location            = module.resource_group.resource_group_location
  sku_name            = "Basic"

  identity = length(var.user_assigned_identity_ids) == 0 ? {
    type         = "SystemAssigned"
    identity_ids = []
    } : {
    type         = "SystemAssigned, UserAssigned"
    identity_ids = var.user_assigned_identity_ids
  }

  local_authentication_enabled = false
  # The Hybrid Worker VM reaches the Automation hybrid service over HTTPS.
  # Set this to false only after adding a private endpoint and private DNS.
  public_network_access_enabled = true

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
    operations_hourly = {
      # Azure requires a GUID, so derive one deterministically from stable names.
      # Unlike uuid(), uuidv5() returns the same value on every plan.
      job_schedule_id = uuidv5("dns", "${var.automation_account_name}.operations.hourly")
      runbook_key     = "operations"
      schedule_key    = "hourly"
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

  webhooks = {
    operations = {
      name        = "operations-webhook"
      runbook_key = "operations"
      expiry_time = "2030-12-31T23:59:59Z"
    }
  }

  # ---------------------------------------------------------------------------
  # Optional features requiring real external resources
  # ---------------------------------------------------------------------------
  # These examples remain in the configuration for documentation, but resolve
  # to empty maps unless enable_external_features is true. Replace every
  # placeholder with a real value before enabling them.

  # This base64encode value is only syntactically valid for terraform plan.
  # Replace it with a base64-encoded, passwordless PFX before terraform apply.
  # Certificate-backed connections below depend on this key.
  certificates = var.enable_external_features ? {
    deployment = {
      name       = "deployment-certificate"
      base64     = base64encode("REPLACE_WITH_PASSWORDLESS_PFX_BYTES")
      exportable = false
    }
  } : {}

  connection_certificates = var.enable_external_features ? {
    azure = {
      name                       = "azure-certificate"
      automation_certificate_key = "deployment"
      subscription_id            = "00000000-0000-0000-0000-000000000000"
    }
  } : {}

  connection_classic_certificates = var.enable_external_features ? {
    classic = {
      name                  = "azure-classic-certificate"
      certificate_asset_key = "deployment"
      subscription_id       = "00000000-0000-0000-0000-000000000000"
      subscription_name     = "example-subscription"
    }
  } : {}

  connection_service_principals = var.enable_external_features ? {
    deployment = {
      name            = "deployment-service-principal"
      application_id  = "00000000-0000-0000-0000-000000000000"
      certificate_key = "deployment"
      subscription_id = "00000000-0000-0000-0000-000000000000"
      tenant_id       = "00000000-0000-0000-0000-000000000000"
    }
  } : {}

  # Credentials are optional and are unrelated to the VM extension identity.
  credentials = var.enable_external_features ? {
    worker = {
      name     = "worker-credential"
      username = "automation-worker"
      password = "REPLACE_WITH_A_SECRET"
    }
  } : {}

  # The group itself has no external prerequisite, so create it by default and
  # display it in the Automation Account portal. Attach the example credential
  # only when the external features are enabled.
  hybrid_runbook_worker_groups = {
    operations = {
      name           = "operations-workers"
      credential_key = var.enable_external_features ? "worker" : null
    }
  }

  # Register the VM in the group using a stable worker GUID.
  hybrid_runbook_workers = {
    primary = {
      worker_group_key = "operations"
      worker_id        = uuidv5("dns", "${var.automation_account_name}.operations.worker")
      vm_resource_id   = module.hybrid_worker_vm.linux_virtual_machine_id
    }
  }

  # Extension-based (V2) is the supported Hybrid Worker platform. The target
  # VM must exist, have a system-assigned identity, and allow outbound HTTPS.
  hybrid_runbook_worker_extensions = {
    primary = {
      hybrid_worker_key = "primary"
      os_type           = "Linux"
    }
  }

  # Each URI must be anonymously downloadable by Azure and contain a valid
  # package of the expected type. example.com placeholder URLs will not work.
  modules = var.enable_external_features ? {
    legacy = {
      name        = "Example.Legacy"
      module_link = { uri = "https://storage.example/valid-module.zip" }
    }
  } : {}

  powershell72_modules = var.enable_external_features ? {
    modern = {
      name        = "Example.Modern"
      module_link = { uri = "https://storage.example/valid-module.zip" }
    }
  } : {}

  python3_packages = var.enable_external_features ? {
    example = {
      name        = "example-package"
      content_uri = "https://storage.example/valid-package.whl"
    }
  } : {}

  # Runtime-environment packages also require a downloadable package URI.
  runtime_environments = var.enable_external_features ? {
    powershell = {
      name             = "pwsh-7-4"
      runtime_language = "PowerShell"
      runtime_version  = "7.4"
    }
  } : {}

  runtime_environment_packages = var.enable_external_features ? {
    az_accounts = {
      name                    = "Az.Accounts"
      runtime_environment_key = "powershell"
      content_uri             = "https://storage.example/valid-package.zip"
    }
  } : {}

  # Compiled node content must be a real MOF document produced from the DSC
  # configuration. The minimal text below is structural documentation only.
  dsc_configurations = var.enable_external_features ? {
    web_server = {
      name             = "WebServer"
      content_embedded = "Configuration WebServer { Node localhost {} }"
    }
  } : {}

  dsc_node_configurations = var.enable_external_features ? {
    localhost = {
      name                  = "WebServer.localhost"
      content_embedded      = "REPLACE_WITH_COMPILED_MOF_CONTENT"
      dsc_configuration_key = "web_server"
    }
  } : {}

  # The repository and branch must exist and the token must have the required
  # repository permissions. Store the token in a sensitive variable in real use.
  source_controls = var.enable_external_features ? {
    repository = {
      name                = "automation-repository"
      folder_path         = "/"
      repository_url      = "https://github.com/organization/repository.git"
      source_control_type = "GitHub"
      branch              = "main"
      security = {
        token      = "REPLACE_WITH_A_PERSONAL_ACCESS_TOKEN"
        token_type = "PersonalAccessToken"
      }
    }
  } : {}

  # A watcher requires a real Hybrid Worker group. It can reference the active
  # operations runbook defined above.
  watchers = var.enable_external_features ? {
    operations = {
      name                           = "operations-watcher"
      execution_frequency_in_seconds = 60
      script_runbook_key             = "operations"
      script_run_on_worker_group_key = "operations"
    }
  } : {}

}
