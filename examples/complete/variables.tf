##-----------------------------------------------------------------------------
## Variables
##-----------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  default     = "rg-automation-example"
  description = "Name of an existing resource group."
}
variable "location" {
  type        = string
  default     = "East US"
  description = "Azure region for the Automation Account."
}
variable "automation_account_name" {
  type        = string
  default     = "aa-complete-example"
  description = "Globally unique Automation Account name."
}
variable "user_assigned_identity_ids" {
  type        = set(string)
  default     = []
  description = "Optional user-assigned identity resource IDs to attach."
}
variable "key_vault_key_id" {
  type        = string
  default     = null
  nullable    = true
  description = "Optional Key Vault key ID for customer-managed key encryption."
}

variable "certificate_base64" {
  type        = string
  default     = "ZXhhbXBsZQ=="
  sensitive   = true
  description = "Base64-encoded PFX certificate."
}
variable "credential_password" {
  type        = string
  default     = "replace-before-apply"
  sensitive   = true
  description = "Password for the example Automation credential."
}
variable "subscription_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}
variable "tenant_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}
variable "application_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}
variable "worker_id" {
  type    = string
  default = "00000000-0000-0000-0000-000000000000"
}
variable "worker_vm_resource_id" {
  type    = string
  default = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-automation-example/providers/Microsoft.Compute/virtualMachines/vm-example"
}
variable "module_content_uri" {
  type    = string
  default = "https://example.com/legacy-module.zip"
}
variable "powershell_module_content_uri" {
  type    = string
  default = "https://example.com/powershell-module.zip"
}
variable "python_package_content_uri" {
  type    = string
  default = "https://example.com/python-package.whl"
}
variable "source_control_repository_url" {
  type    = string
  default = "https://github.com/example/automation.git"
}
variable "source_control_token" {
  type      = string
  default   = "replace-before-apply"
  sensitive = true
}
