###########################
# Resource Variables
###########################
locals {
  # Loose 5-field cron expression check: five whitespace-separated fields. This intentionally
  # does not validate the semantic range of each field, only the overall shape, since the
  # provider performs authoritative validation server-side.
  run_schedule_rule_cron_pattern = "^[^\\s]+\\s+[^\\s]+\\s+[^\\s]+\\s+[^\\s]+\\s+[^\\s]+$"
}

variable "run_schedule_rules" {
  description = <<-EOT
    Map of Scalr run schedule rules keyed by a caller-supplied logical name. Each entry manages
    one `scalr_run_schedule_rule` resource, scheduling a recurring apply, destroy, or refresh
    run for a workspace.

    Fields:
      - schedule:      (Required) Cron expression (5 fields, UTC) for the scheduled run.
      - schedule_mode: (Required) Mode of the scheduled run. Valid values are "apply",
                        "destroy", and "refresh".
      - workspace_id:  (Required) ID of the workspace, in the format "ws-<RANDOM STRING>".

    Example:
      run_schedule_rules = {
        nightly_apply = {
          schedule      = "0 4 * * *"
          schedule_mode = "apply"
          workspace_id  = "ws-xxxxxxxxxx"
        }
      }
  EOT
  type = map(object({
    schedule      = string
    schedule_mode = string
    workspace_id  = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.run_schedule_rules : contains(["apply", "destroy", "refresh"], value.schedule_mode)
    ])
    error_message = "Each run_schedule_rules entry's schedule_mode must be one of 'apply', 'destroy', or 'refresh'."
  }

  validation {
    condition = alltrue([
      for key, value in var.run_schedule_rules : can(regex(local.run_schedule_rule_cron_pattern, value.schedule))
    ])
    error_message = "Each run_schedule_rules entry's schedule must be a 5-field cron expression (e.g. \"0 4 * * *\")."
  }
}
