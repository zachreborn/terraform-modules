###########################
# Resource Variables
###########################
variable "slack_integrations" {
  description = <<-EOT
    Map of Scalr Slack integrations keyed by a caller-supplied logical name. Each entry
    manages one `scalr_slack_integration` resource, sending a Slack notification to a channel
    when configured run events occur. The Slack workspace must already be connected to the
    Scalr account before using this resource.

    Fields:
      - name:         (Required) Name of the Slack integration.
      - channel_id:   (Required) Slack channel ID the event will be sent to (found in the
                       Slack UI's channel settings/info popup).
      - events:       (Required) Set of run events to notify on. Valid values are
                       "run_approval_required", "run_success", "run_errored", and
                       "drift_detected".
      - environments: (Required) List of environments where events should be triggered.
      - workspaces:   (Optional) List of workspaces where events should be triggered. Must be
                       within the given environments; if omitted for an environment, events
                       trigger for all of its workspaces.
      - run_mode:     (Optional) What type of runs should be reported. Valid values are "all",
                       "apply", and "dry".
      - account_id:   (Optional) ID of the account, in the format "acc-<RANDOM STRING>". Falls
                       back to var.account_id when unset.

    Example:
      slack_integrations = {
        run_notifications = {
          name         = "my-channel"
          channel_id   = "C0000000000"
          events       = ["run_approval_required", "run_errored"]
          environments = ["env-xxxxxxxxxx"]
        }
      }
  EOT
  type = map(object({
    name         = string
    channel_id   = string
    events       = set(string)
    environments = set(string)
    workspaces   = optional(set(string))
    run_mode     = optional(string)
    account_id   = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.slack_integrations : alltrue([
        for event in value.events : contains(["run_approval_required", "run_success", "run_errored", "drift_detected"], event)
      ])
    ])
    error_message = "Each slack_integrations entry's events must only contain 'run_approval_required', 'run_success', 'run_errored', and/or 'drift_detected'."
  }

  validation {
    condition = alltrue([
      for key, value in var.slack_integrations : length(value.events) > 0
    ])
    error_message = "Each slack_integrations entry must specify at least one event."
  }

  validation {
    condition = alltrue([
      for key, value in var.slack_integrations : value.run_mode == null || contains(["all", "apply", "dry"], value.run_mode)
    ])
    error_message = "Each slack_integrations entry's run_mode must be one of 'all', 'apply', or 'dry'."
  }
}

###########################
# General Variables
###########################
variable "account_id" {
  description = "(Optional) Default Scalr account ID, in the format \"acc-<RANDOM STRING>\", used for any slack_integrations entry that does not set its own account_id."
  type        = string
  default     = null
}
