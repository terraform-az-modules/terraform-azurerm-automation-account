variable "resource_group_name" {
  type    = string
  default = "rg-automation-example"
}
variable "location" {
  type    = string
  default = "East US"
}
variable "automation_account_name" {
  type    = string
  default = "aa-runbook-example"
}
##-----------------------------------------------------------------------------
## Resource Group
##-----------------------------------------------------------------------------
variable "enabled" {
  type        = bool
  default     = true
  description = "Set to false to prevent the module from creating any resources."
}

variable "create" {
  type        = string
  default     = "90m"
  description = "Used when creating the Resource Group."
}

variable "read" {
  type        = string
  default     = "5m"
  description = "Used when retrieving the Resource Group."
}

variable "update" {
  type        = string
  default     = "90m"
  description = "Used when updating the Resource Group."
}

variable "delete" {
  type        = string
  default     = "90m"
  description = "Used when deleting the Resource Group."
}

variable "resource_lock_enabled" {
  type        = bool
  default     = false
  description = "Enable or disable lock resource"
}

variable "lock_level" {
  type        = string
  default     = "CanNotDelete"
  description = "Specifies the lock level for the resource group to prevent accidental changes."
}

variable "notes" {
  type        = string
  default     = "This Resource Group is locked by terrafrom"
  description = "Specifies some notes about the lock. Maximum of 512 characters. Changing this forces a new resource to be created."
}
