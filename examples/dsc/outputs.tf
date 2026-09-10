output "dsc_resource_ids" {
  value = {
    configurations      = module.automation_account.resource_ids.dsc_configurations
    node_configurations = module.automation_account.resource_ids.dsc_node_configurations
  }
}
