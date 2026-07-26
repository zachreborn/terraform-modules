###########################
# Resource Variables
###########################
locals {
  # Loose 5-field cron expression check: five whitespace-separated fields. This intentionally
  # does not validate the semantic range of each field (e.g. "60" in the minutes field), only
  # the overall shape, since the provider performs authoritative validation server-side.
  workspace_run_schedule_cron_pattern = "^[^\\s]+\\s+[^\\s]+\\s+[^\\s]+\\s+[^\\s]+\\s+[^\\s]+$"
}

variable "workspace_run_schedules" {
  description = <<-EOT
    Map of Scalr workspace run schedules keyed by a caller-supplied logical name. Each entry
    manages one `scalr_workspace_run_schedule` resource, automating recurring apply and/or
    destroy runs for a workspace.

    Fields:
      - workspace_id:     (Required) ID of the workspace, in the format "ws-<RANDOM STRING>".
      - apply_schedule:   (Optional) Cron expression (5 fields, UTC) for when an apply run
                           should be created.
      - destroy_schedule: (Optional) Cron expression (5 fields, UTC) for when a destroy run
                           should be created.

    At least one of apply_schedule or destroy_schedule must be set.

    Example:
      workspace_run_schedules = {
        nightly_refresh = {
          workspace_id   = "ws-xxxxxxxxxx"
          apply_schedule = "30 3 5 3-5 2"
        }
      }
  EOT
  type = map(object({
    workspace_id     = string
    apply_schedule   = optional(string)
    destroy_schedule = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.workspace_run_schedules : value.apply_schedule != null || value.destroy_schedule != null
    ])
    error_message = "Each workspace_run_schedules entry must set at least one of apply_schedule or destroy_schedule."
  }

  validation {
    condition = alltrue([
      for key, value in var.workspace_run_schedules :
      value.apply_schedule == null || can(regex(local.workspace_run_schedule_cron_pattern, value.apply_schedule))
    ])
    error_message = "Each workspace_run_schedules entry's apply_schedule must be a 5-field cron expression (e.g. \"30 3 5 3-5 2\")."
  }

  validation {
    condition = alltrue([
      for key, value in var.workspace_run_schedules :
      value.destroy_schedule == null || can(regex(local.workspace_run_schedule_cron_pattern, value.destroy_schedule))
    ])
    error_message = "Each workspace_run_schedules entry's destroy_schedule must be a 5-field cron expression (e.g. \"30 4 5 3-5 2\")."
  }
}
