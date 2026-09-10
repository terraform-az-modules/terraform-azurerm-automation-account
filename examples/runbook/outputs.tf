output "runbook_ids" {
  value = module.automation_account.resource_ids.runbooks
}
output "webhook_uris" {
  value     = module.automation_account.webhook_uris
  sensitive = true
}
