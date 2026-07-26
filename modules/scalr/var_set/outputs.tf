###########################
# Scalr Var Set
###########################

output "ids" {
  description = "Map of Scalr variable set IDs, keyed by the same keys as var.var_sets."
  value       = { for k, v in scalr_var_set.this : k => v.id }
}

output "account_ids" {
  description = "Map of the Scalr account ID each variable set belongs to, keyed by the same keys as var.var_sets."
  value       = { for k, v in scalr_var_set.this : k => v.account_id }
}

###########################
# Scalr Workspace Var Set Links
###########################

output "workspace_link_ids" {
  description = "Map of workspace/var set link resource IDs, keyed by the same keys as var.workspace_links."
  value       = module.workspace_link.ids
}

output "workspace_links" {
  description = "Map of the full resolved link (workspace_id, var_set_id, id) for each var.workspace_links entry."
  value       = module.workspace_link.links
}
