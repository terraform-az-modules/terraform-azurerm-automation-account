##-----------------------------------------------------------------------------
## Locals
##-----------------------------------------------------------------------------
locals {
  user_assigned_identity_ids = var.identity == null ? toset([]) : var.identity.identity_ids
}
