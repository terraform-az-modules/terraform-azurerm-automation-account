# Complete example

This example calls the root module once and exercises account security, identities, optional CMK encryption, certificates, every connection form, credentials, Hybrid Workers, legacy and language packages, a runbook and schedule, source control, all variable types, a watcher, and a webhook.

Provide `resource_group_name`, `location`, and `automation_account_name`. When `key_vault_key_id` is set, provide exactly one value in `user_assigned_identity_ids`; that identity must have permission to use the Key Vault key.

```bash
terraform init
terraform plan \
  -var='resource_group_name=rg-example' \
  -var='location=West Europe' \
  -var='automation_account_name=aa-example-001'
```

No runbooks, schedules, or other Automation resources are created.
