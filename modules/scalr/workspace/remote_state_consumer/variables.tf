###########################
# Scalr Workspace Remote State Consumer
###########################

variable "workspace_remote_state_consumers" {
  description = <<-EOT
    (Required) Map of workspace remote state consumers (`scalr_workspace_remote_state_consumer`) to create,
    keyed by a caller-chosen logical name. Each entry allows one consumer workspace to read the state of one
    source workspace. Fields:
      - workspace_id: (Required) ID of the source workspace whose state is shared, in the format
                      `ws-<RANDOM STRING>`. This workspace must have `remote_state_sharing = false`.
      - consumer_id:  (Required) ID of the workspace that is allowed to read the source workspace's state, in
                      the format `ws-<RANDOM STRING>`. Must differ from workspace_id: a workspace cannot be a
                      remote state consumer of itself.

    Changing either ID on an existing entry forces that entry to be re-created. To let several workspaces read
    the same source workspace, add one entry per consumer.

    Example:
      workspace_remote_state_consumers = {
        app_reads_network_state = {
          workspace_id = "ws-xxxxxxxxxx"
          consumer_id  = "ws-yyyyyyyyyy"
        }
      }
  EOT
  type = map(object({
    workspace_id = string
    consumer_id  = string
  }))
  default  = {}
  nullable = false

  validation {
    # Conditional, not a bare `trimspace(...) != "" && ...`: Terraform evaluates every operand of `&&`/`||`, so
    # trimspace(null) would raise a raw "argument must not be null" error instead of this message when an ID is
    # null. The conditional only reports errors from the branch it selects.
    condition = alltrue([
      for k, v in var.workspace_remote_state_consumers : (
        v.workspace_id == null || v.consumer_id == null ? false :
        trimspace(v.workspace_id) != "" && trimspace(v.consumer_id) != ""
      )
    ])
    error_message = "Each workspace_remote_state_consumers entry's workspace_id and consumer_id must be set to non-empty workspace IDs (not null or blank)."
  }

  validation {
    condition = alltrue([
      for k, v in var.workspace_remote_state_consumers : v.workspace_id != v.consumer_id
    ])
    error_message = "Each workspace_remote_state_consumers entry's consumer_id must differ from its workspace_id: a workspace cannot be a remote state consumer of itself."
  }

  validation {
    # A null ID cannot be interpolated into the pair key, so such an entry gets a unique placeholder key here and
    # is reported by the blank/null validation above instead.
    condition = (
      length(distinct([
        for k, v in var.workspace_remote_state_consumers : (
          v.workspace_id == null || v.consumer_id == null ? "null-id:${k}" : "${v.workspace_id}/${v.consumer_id}"
        )
      ]))
      == length(var.workspace_remote_state_consumers)
    )
    error_message = "Each workspace_remote_state_consumers entry must be a unique workspace_id/consumer_id pair; the same consumer cannot be granted access to the same workspace twice."
  }
}
