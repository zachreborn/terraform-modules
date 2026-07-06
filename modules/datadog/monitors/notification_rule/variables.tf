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
    # Exactly one of recipients or conditional_recipients must be set.
    # Use recipients for simple routing; use conditional_recipients for conditional routing.
    recipients = optional(set(string), null)

    ###########################
    # filter Block (Required)
    ###########################
    # Specifies which monitors this rule applies to.
    # Exactly one of scope or tags must be set within the filter block.
    filter = object({
      scope = optional(string, null)
      tags  = optional(set(string), null)
    })

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
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.notification_rules :
      (v.recipients != null) != (v.conditional_recipients != null)
    ])
    error_message = "Exactly one of recipients or conditional_recipients must be set per notification rule."
  }

  validation {
    condition = alltrue([
      for k, v in var.notification_rules :
      (v.filter.scope != null) != (v.filter.tags != null)
    ])
    error_message = "Exactly one of filter.scope or filter.tags must be set per notification rule."
  }
}
