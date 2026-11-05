###########################
# Scalr Workspace Remote State Consumer
###########################

output "ids" {
  description = "Map of Scalr workspace remote state consumer resource IDs (format '<workspace_id>/<consumer_id>'), keyed by the same keys as var.workspace_remote_state_consumers."
  value       = { for k, v in scalr_workspace_remote_state_consumer.this : k => v.id }
}

output "links" {
  description = "Map of the full resolved link (workspace_id, consumer_id, id) for each entry, keyed by the same keys as var.workspace_remote_state_consumers. Useful for callers/tests that need to prove which workspace_id/consumer_id combination was actually wired into each resource."
  value = {
    for k, v in scalr_workspace_remote_state_consumer.this : k => {
      id           = v.id
      workspace_id = v.workspace_id
      consumer_id  = v.consumer_id
    }
  }
}
