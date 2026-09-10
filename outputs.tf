##-----------------------------------------------------------------------------
## Outputs
##-----------------------------------------------------------------------------
output "id" {
  value       = azurerm_automation_account.this.id
  description = "Resource ID of the Automation Account."
}
output "name" {
  value       = azurerm_automation_account.this.name
  description = "Name of the Automation Account."
}
output "resource_group_name" {
  value       = azurerm_automation_account.this.resource_group_name
  description = "Name of the resource group containing the Automation Account."
}
output "location" {
  value       = azurerm_automation_account.this.location
  description = "Azure region of the Automation Account."
}
output "identity" {
  value       = try(azurerm_automation_account.this.identity[0], null)
  description = "Managed identity attributes of the Automation Account."
}
output "principal_id" {
  value       = try(azurerm_automation_account.this.identity[0].principal_id, null)
  description = "Principal ID of the system-assigned managed identity, when enabled."
}
output "tenant_id" {
  value       = try(azurerm_automation_account.this.identity[0].tenant_id, null)
  description = "Tenant ID of the system-assigned managed identity, when enabled."
}
output "dsc_server_endpoint" {
  value       = azurerm_automation_account.this.dsc_server_endpoint
  description = "DSC server endpoint associated with the Automation Account."
}
output "hybrid_service_url" {
  value       = azurerm_automation_account.this.hybrid_service_url
  description = "Hybrid service URL used for Hybrid Worker onboarding."
}

output "dsc_primary_access_key" {
  value       = azurerm_automation_account.this.dsc_primary_access_key
  description = "Primary DSC access key."
  sensitive   = true
}

output "dsc_secondary_access_key" {
  value       = azurerm_automation_account.this.dsc_secondary_access_key
  description = "Secondary DSC access key."
  sensitive   = true
}

output "resource_ids" {
  value = {
    certificates                    = { for key, resource in azurerm_automation_certificate.this : key => resource.id }
    connection_types                = { for key, resource in azurerm_automation_connection_type.this : key => resource.id }
    connections                     = { for key, resource in azurerm_automation_connection.this : key => resource.id }
    connection_certificates         = { for key, resource in azurerm_automation_connection_certificate.this : key => resource.id }
    connection_classic_certificates = { for key, resource in azurerm_automation_connection_classic_certificate.this : key => resource.id }
    connection_service_principals   = { for key, resource in azurerm_automation_connection_service_principal.this : key => resource.id }
    credentials                     = { for key, resource in azurerm_automation_credential.this : key => resource.id }
    dsc_configurations              = { for key, resource in azurerm_automation_dsc_configuration.this : key => resource.id }
    dsc_node_configurations         = { for key, resource in azurerm_automation_dsc_nodeconfiguration.this : key => resource.id }
    hybrid_worker_groups            = { for key, resource in azurerm_automation_hybrid_runbook_worker_group.this : key => resource.id }
    hybrid_workers                  = { for key, resource in azurerm_automation_hybrid_runbook_worker.this : key => resource.id }
    job_schedules                   = { for key, resource in azurerm_automation_job_schedule.this : key => resource.id }
    modules                         = { for key, resource in azurerm_automation_module.this : key => resource.id }
    powershell72_modules            = { for key, resource in azurerm_automation_powershell72_module.this : key => resource.id }
    python3_packages                = { for key, resource in azurerm_automation_python3_package.this : key => resource.id }
    runbooks                        = { for key, resource in azurerm_automation_runbook.this : key => resource.id }
    runtime_environments            = { for key, resource in azurerm_automation_runtime_environment.this : key => resource.id }
    runtime_environment_packages    = { for key, resource in azurerm_automation_runtime_environment_package.this : key => resource.id }
    schedules                       = { for key, resource in azurerm_automation_schedule.this : key => resource.id }
    source_controls                 = { for key, resource in azurerm_automation_source_control.this : key => resource.id }
    bool_variables                  = { for key, resource in azurerm_automation_variable_bool.this : key => resource.id }
    datetime_variables              = { for key, resource in azurerm_automation_variable_datetime.this : key => resource.id }
    int_variables                   = { for key, resource in azurerm_automation_variable_int.this : key => resource.id }
    object_variables                = { for key, resource in azurerm_automation_variable_object.this : key => resource.id }
    string_variables                = { for key, resource in azurerm_automation_variable_string.this : key => resource.id }
    watchers                        = { for key, resource in azurerm_automation_watcher.this : key => resource.id }
    webhooks                        = { for key, resource in azurerm_automation_webhook.this : key => resource.id }
  }
  description = "Resource IDs of all optional Automation Account child resources, grouped by type and keyed by input map key."
}

output "webhook_uris" {
  value       = { for key, resource in azurerm_automation_webhook.this : key => resource.uri }
  description = "Generated webhook URIs keyed by input map key."
  sensitive   = true
}
