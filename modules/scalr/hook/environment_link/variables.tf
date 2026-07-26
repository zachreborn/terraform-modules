###########################
# Resource Variables
###########################
variable "environment_hooks" {
  description = <<-EOT
    Map of Scalr environment hook links keyed by a caller-supplied logical name. Each entry
    manages one `scalr_environment_hook` resource, attaching a hook (see the sibling
    `hook` submodule) to a specific environment for one or more workflow events.

    Fields:
      - hook_id:        (Required) ID of the hook, in the format "hook-<RANDOM STRING>".
      - environment_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>".
      - events:         (Required) Set of events that trigger the hook execution. Valid values
                         are "pre-init", "pre-plan", "post-plan", "pre-apply", "post-apply", or
                         the single-element set ["*"] to select all events.

    Example:
      environment_hooks = {
        notify_prod = {
          hook_id        = module.hook.ids["notify"]
          environment_id = "env-xxxxxxxxxx"
          events         = ["pre-apply", "post-apply"]
        }
      }
  EOT
  type = map(object({
    hook_id        = string
    environment_id = string
    events         = set(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.environment_hooks : length(value.events) > 0
    ])
    error_message = "Each environment_hooks entry must specify at least one event."
  }

  validation {
    condition = alltrue([
      for key, value in var.environment_hooks : (
        (length(value.events) == 1 && contains(value.events, "*")) ||
        alltrue([for event in value.events : contains(local.environment_hook_valid_events, event)])
      )
    ])
    error_message = "Each environment_hooks entry's events must be either the single-element set [\"*\"] or a set containing only 'pre-init', 'pre-plan', 'post-plan', 'pre-apply', and/or 'post-apply'."
  }
}
