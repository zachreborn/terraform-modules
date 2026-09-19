###########################
# Resource Variables
###########################
variable "run_triggers" {
  description = <<-EOT
    Map of Scalr run triggers keyed by a caller-supplied logical name. Each entry manages one
    `scalr_run_trigger` resource, chaining an upstream workspace's successful run into an
    automatic run in a downstream workspace.

    Fields:
      - downstream_id: (Required) ID of the workspace in which new runs will be triggered.
      - upstream_id:   (Required) ID of the upstream workspace.

    Example:
      run_triggers = {
        promote_to_staging = {
          downstream_id = "ws-downstream0"
          upstream_id   = "ws-upstream000"
        }
      }
  EOT
  type = map(object({
    downstream_id = string
    upstream_id   = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.run_triggers : value.downstream_id != value.upstream_id
    ])
    error_message = "Each run_triggers entry's downstream_id and upstream_id must refer to different workspaces; a workspace cannot trigger itself."
  }
}
