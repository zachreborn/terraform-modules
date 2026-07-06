############################################################
# Organization
############################################################

output "organization" {
  description = "Full set of organization submodule outputs (id, arn, roots, master_account_id, SCP ids/arns, etc.), or null when var.organization was not set."
  value       = try(module.organization["this"], null)
}

############################################################
# Organizational Units
############################################################

output "organizational_unit_ids" {
  description = "Map of Organizational Unit IDs, keyed by the same keys as var.organizational_units. If an entry has neither parent_id nor parent_key and cannot default to an Organization root (var.organization not set), the nested ou module's own validation fails with a message explaining the fix."
  value       = module.organizational_units.ids
}

output "organizational_unit_arns" {
  description = "Map of Organizational Unit ARNs, keyed by the same keys as var.organizational_units."
  value       = module.organizational_units.arns
}

output "organizational_unit_accounts" {
  description = "Map of the list of accounts in each Organizational Unit, keyed by the same keys as var.organizational_units."
  value       = module.organizational_units.accounts
}

############################################################
# Accounts
############################################################

output "account_ids" {
  description = "Map of AWS Organization account IDs, keyed by the same keys as var.accounts."
  value       = module.accounts.ids
}

output "account_arns" {
  description = "Map of AWS Organization account ARNs, keyed by the same keys as var.accounts."
  value       = module.accounts.arns
}

output "account_tags_all" {
  description = "Map of the resolved tags for each account, keyed by the same keys as var.accounts."
  value       = module.accounts.tags_all
}
