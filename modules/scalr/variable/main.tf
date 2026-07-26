###########################
# Provider Configuration
###########################
terraform {
  # >= 1.11.0 is required because the value_wo argument below is a write-only resource argument.
  # Both Terraform and OpenTofu added write-only argument support in their respective 1.11.0
  # releases; the argument is present in this resource's configuration (even when unset, i.e.
  # null) regardless of whether a caller actually uses var.values_wo, so this floor applies
  # unconditionally, not just when write-only values are in use.
  required_version = ">= 1.11.0"
  required_providers {
    scalr = {
      source  = "registry.scalr.io/scalr/scalr"
      version = ">= 3.17.0"
    }
  }
}

###########################
# Scalr Variable
###########################

resource "scalr_variable" "this" {
  for_each = var.variables

  key              = each.value.key
  value            = lookup(var.values, each.key, null)
  value_wo         = lookup(var.values_wo, each.key, null)
  value_wo_version = each.value.value_wo_version
  category         = each.value.category
  hcl              = each.value.hcl
  sensitive        = each.value.sensitive
  final            = each.value.final
  force            = each.value.force
  description      = each.value.description
  account_id       = each.value.account_id
  environment_id   = each.value.environment_id
  workspace_id     = each.value.workspace_id
  var_set_id       = each.value.var_set_id
}
