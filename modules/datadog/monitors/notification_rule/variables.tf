###########################
# Resource Variables
###########################

variable "notification_rules" {
  description = "Map of Datadog monitor notification rule configurations keyed by logical name. Each entry maps to one datadog_monitor_notification_rule resource."
  type = map(object({
    ###########################
    # Required Fields
    ###########################
    name = string

    ###########################
    # Optional Fields
    ###########################
    # recipients and conditional_recipients are mutually exclusive.
    # Use recipients for simple routing; use conditional_recipients for conditional routing.
    recipients = optional(set(string), null)

    ###########################
    # filter Block
    ###########################
    # Specifies which monitors this rule applies to.
    # scope and tags are mutually exclusive within the filter block.
    filter = optional(object({
      scope = optional(string, null)
      tags  = optional(set(string), null)
    }), null)

    ###########################
    # conditional_recipients Block
    ###########################
    # Cannot be used with recipients.
    conditional_recipients = optional(object({
      fallback_recipients = optional(set(string), null)
      conditions = optional(list(object({
        scope      = string
        recipients = set(string)
      })), null)
    }), null)
  }))

  validation {
    condition = alltrue([
      for k, v in var.notification_rules :
      !(v.recipients != null && v.conditional_recipients != null)
    ])
    error_message = "recipients and conditional_recipients are mutually exclusive. Set only one per notification rule."
  }
}
