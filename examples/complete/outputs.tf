##-----------------------------------------------------------------------------
## Outputs
##-----------------------------------------------------------------------------
output "automation_account_id" {
  value       = module.automation_account.id
  description = "Resource ID of the Automation Account."
}
output "automation_account_principal_id" {
  value       = module.automation_account.principal_id
  description = "Principal ID of the system-assigned identity."
}

output "resource_ids" {
  value       = module.automation_account.resource_ids
  description = "IDs of child resources created by the complete example."
}

output "webhook_uris" {
  value       = module.automation_account.webhook_uris
  description = "Generated webhook URIs."
  sensitive   = true
}
