###########################
# Resource Variables
###########################

variable "config_policies" {
  description = "Map of Datadog monitor config policy configurations keyed by logical name. Each entry maps to one datadog_monitor_config_policy resource."
  type = map(object({
    ###########################
    # Required Fields
    ###########################
    policy_type = string

    ###########################
    # tag_policy Block
    ###########################
    # Required when policy_type is "tag". Defines a tag enforcement policy for monitors.
    tag_policy = optional(object({
      tag_key          = string
      tag_key_required = bool
      valid_tag_values = list(string)
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.config_policies : contains(["tag"], v.policy_type)
    ])
    error_message = "policy_type must be 'tag'. This is the only currently supported value."
  }

  validation {
    condition = alltrue([
      for k, v in var.config_policies : v.policy_type != "tag" || v.tag_policy != null
    ])
    error_message = "tag_policy must be set when policy_type is 'tag'."
  }
}
