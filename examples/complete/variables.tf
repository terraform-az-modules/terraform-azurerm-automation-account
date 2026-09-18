##-----------------------------------------------------------------------------
## Variables
##-----------------------------------------------------------------------------
variable "resource_group_name" {
  type        = string
  default     = "automation-example"
  description = "Name label used by the resource-group module."
}
variable "location" {
  type        = string
  default     = "Canada Central"
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

variable "enable_external_features" {
  type        = bool
  default     = false
  description = "Enables examples that require real certificates, workers, packages, compiled DSC content, and source-control credentials. Replace all placeholders before setting this to true."
}
