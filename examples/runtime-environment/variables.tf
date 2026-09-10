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
  default = "aa-runtime-example"
}
variable "package_content_uri" {
  type        = string
  default     = "https://example.com/Az.Accounts.zip"
  description = "URI of a package compatible with the runtime environment."
}
