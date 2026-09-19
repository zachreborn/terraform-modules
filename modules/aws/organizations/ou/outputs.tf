output "ids" {
  description = "Map of Organizational Unit IDs, keyed by the same keys as var.organizational_units."
  value       = { for k, v in local.all_organizational_units : k => v.id }

  precondition {
    condition     = length(local.all_organizational_units) == length(var.organizational_units)
    error_message = "One or more organizational_units entries could not be resolved into an OU. This usually means a parent_key chain exceeds the 4 supported levels of nesting, or contains a cycle. Check that every parent_key ultimately resolves back to an entry that sets a literal parent_id."
  }
}

output "arns" {
  description = "Map of Organizational Unit ARNs, keyed by the same keys as var.organizational_units."
  value       = { for k, v in local.all_organizational_units : k => v.arn }
}

output "accounts" {
  description = "Map of the list of accounts in each Organizational Unit, keyed by the same keys as var.organizational_units."
  value       = { for k, v in local.all_organizational_units : k => v.accounts }
}
