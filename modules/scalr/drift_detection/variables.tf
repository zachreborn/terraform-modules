###########################
# Resource Variables
###########################
variable "drift_detections" {
  description = <<-EOT
    Map of Scalr drift detection schedulers keyed by a caller-supplied logical name. Each entry
    manages one `scalr_drift_detection` resource, periodically checking one or more workspaces
    in an environment for infrastructure drift.

    Fields:
      - environment_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>".
      - check_period:   (Required) Check period for drift detection. Valid values are "daily"
                         and "weekly".
      - run_mode:       (Optional, default "refresh-only") Run mode for drift detection. Valid
                         values are "refresh-only" and "plan".
      - workspace_filters: (Optional) Filters for which workspaces are included in drift
                         detection. At most one of name_patterns, environment_types, or tags may
                         be set per entry.
          - name_patterns:     (Optional) Workspace name patterns to include. Supports the "*"
                                wildcard (e.g. "prod-*").
          - environment_types: (Optional) Workspace environment types to include. Valid values
                                are "production", "staging", "testing", "development", and
                                "unmapped".
          - tags:              (Optional) Workspace tags to include. A workspace matches if it
                                has at least one of the specified tags.

    Example:
      drift_detections = {
        prod_weekly = {
          environment_id = "env-xxxxxxxxxx"
          check_period   = "weekly"
          run_mode       = "plan"
          workspace_filters = {
            name_patterns = ["prod", "stage-*"]
          }
        }
      }
  EOT
  type = map(object({
    environment_id = string
    check_period   = string
    run_mode       = optional(string, "refresh-only")
    workspace_filters = optional(object({
      name_patterns     = optional(set(string))
      environment_types = optional(set(string))
      tags              = optional(set(string))
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.drift_detections : contains(["daily", "weekly"], value.check_period)
    ])
    error_message = "Each drift_detections entry's check_period must be one of 'daily' or 'weekly'."
  }

  validation {
    condition = alltrue([
      for key, value in var.drift_detections : contains(["refresh-only", "plan"], value.run_mode)
    ])
    error_message = "Each drift_detections entry's run_mode must be one of 'refresh-only' or 'plan'."
  }

  validation {
    condition = alltrue([
      for key, value in var.drift_detections : (
        value.workspace_filters == null ||
        length([
          for filter_type in [
            value.workspace_filters.name_patterns,
            value.workspace_filters.environment_types,
            value.workspace_filters.tags,
          ] : filter_type if filter_type != null && length(filter_type) > 0
        ]) <= 1
      )
    ])
    error_message = "Each drift_detections entry's workspace_filters may set at most one of name_patterns, environment_types, or tags."
  }

  validation {
    condition = alltrue(flatten([
      for key, value in var.drift_detections : [
        for environment_type in coalesce(try(value.workspace_filters.environment_types, null), []) :
        contains(["production", "staging", "testing", "development", "unmapped"], environment_type)
      ]
    ]))
    error_message = "Each drift_detections entry's workspace_filters.environment_types must only contain 'production', 'staging', 'testing', 'development', and/or 'unmapped'."
  }
}
