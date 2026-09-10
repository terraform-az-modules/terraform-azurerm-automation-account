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
  default = "aa-basic-example"
}
variable "environment" {
  type        = string
  default     = "dev"
  description = "Deployment environment such as dev, qa, stage, or prod."
}
