provider "azurerm" {
  features {}
}

module "automation_account" {
  source = "../.."

  name                = var.automation_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  runtime_environments = {
    powershell = {
      name             = "pwsh-7-4"
      runtime_language = "PowerShell"
      runtime_version  = "7.4"
    }
  }

  runtime_environment_packages = {
    az_accounts = {
      name                    = "Az.Accounts"
      runtime_environment_key = "powershell"
      content_uri             = var.package_content_uri
    }
  }

  runbooks = {
    runtime = {
      name                    = "runtime-example"
      runbook_type            = "PowerShell"
      log_progress            = true
      log_verbose             = false
      runtime_environment_key = "powershell"
      content                 = "Get-AzContext"
    }
  }
}
