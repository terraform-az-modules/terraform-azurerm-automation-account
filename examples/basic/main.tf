provider "azurerm" {
  features {}
}

module "automation_account" {
  source = "../.."

  name                          = var.automation_account_name
  resource_group_name           = var.resource_group_name
  location                      = var.location
  sku_name                      = "Basic"
  local_authentication_enabled  = false
  public_network_access_enabled = true
  identity = {
    type = "SystemAssigned"
  }
  tags = {
    environment = var.environment
    managed-by  = "terraform"
  }
}
