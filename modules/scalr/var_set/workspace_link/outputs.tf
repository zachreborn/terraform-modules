###########################
# Scalr Workspace Var Set Link
###########################

output "ids" {
  description = "Map of Scalr workspace/var set link resource IDs (format '<workspace_id>/<var_set_id>'), keyed by the same keys as var.workspace_var_set_links."
  value       = { for k, v in scalr_workspace_var_set.this : k => v.id }
}

output "links" {
  description = "Map of the full resolved link (workspace_id, var_set_id, id) for each entry, keyed by the same keys as var.workspace_var_set_links. Useful for callers/tests that need to prove which workspace_id/var_set_id combination was actually wired into each resource."
  value = {
    for k, v in scalr_workspace_var_set.this : k => {
      id           = v.id
      workspace_id = v.workspace_id
      var_set_id   = v.var_set_id
    }
  }
}
