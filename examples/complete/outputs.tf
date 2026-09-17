##-----------------------------------------------------------------------------
## Outputs
##-----------------------------------------------------------------------------
output "resource_group_id" {
  value       = module.resource_group.resource_group_id
  description = "Resource ID of the resource group created by this example."
}

output "hybrid_worker_vm_id" {
  value       = module.hybrid_worker_vm.linux_virtual_machine_id
  description = "Resource ID of the Linux VM used by the extension-based Hybrid Worker."
}

output "hybrid_worker_private_ip_addresses" {
  value       = module.hybrid_worker_vm.network_interface_private_ip_addresses
  description = "Private IP addresses assigned to the Hybrid Worker VM."
}

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
