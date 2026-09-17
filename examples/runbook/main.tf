provider "azurerm" {
  features {}
}

module "automation_account" {
  source = "../.."

  name                = var.automation_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  runbooks = {
    hello = {
      name         = "hello-world"
      runbook_type = "PowerShell"
      log_progress = true
      log_verbose  = true
      content      = "Write-Output 'Hello from Azure Automation'"
    }
  }

  schedules = {
    daily = {
      name      = "daily"
      frequency = "Day"
      interval  = 1
      timezone  = "UTC"
    }
  }

  job_schedules = {
    hello_daily = {
      # Azure requires a GUID, so derive one deterministically from stable names.
      # Unlike uuid(), uuidv5() returns the same value on every plan.
      job_schedule_id = uuidv5("dns", "${var.automation_account_name}.hello.daily")
      runbook_key     = "hello"
      schedule_key    = "daily"
    }
  }

  webhooks = {
    hello = {
      name        = "hello-webhook"
      runbook_key = "hello"
      expiry_time = "2030-12-31T23:59:59Z"
    }
  }

  string_variables = {
    environment = {
      name  = "Environment"
      value = "example"
    }
  }
}
