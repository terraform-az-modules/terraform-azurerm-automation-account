provider "azurerm" {
  features {}
}

module "automation_account" {
  source = "../.."

  name                = var.automation_account_name
  resource_group_name = var.resource_group_name
  location            = var.location

  dsc_configurations = {
    web_server = {
      name             = "WebServer"
      content_embedded = <<-POWERSHELL
        Configuration WebServer {
          Node localhost {
            WindowsFeature IIS { Name = "Web-Server"; Ensure = "Present" }
          }
        }
      POWERSHELL
    }
  }

  dsc_node_configurations = {
    localhost = {
      name                  = "WebServer.localhost"
      content_embedded      = "instance of OMI_ConfigurationDocument {}"
      dsc_configuration_key = "web_server"
    }
  }
}
