###########################
# Resource Variables
###########################
variable "slack_channels" {
  description = "Map of Slack channel integrations keyed by a logical name. Each entry configures one Datadog notification channel in a Slack workspace."
  type = map(object({
    account_name = string
    channel_name = string
    display = optional(object({
      message      = optional(bool, true)
      mute_buttons = optional(bool, true)
      notified     = optional(bool, true)
      snapshot     = optional(bool, true)
      tags         = optional(bool, true)
    }), {})
  }))
  default = {}
}
