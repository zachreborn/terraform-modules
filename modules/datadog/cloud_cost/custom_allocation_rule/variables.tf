###########################
# Resource Variables
###########################

variable "allocation_rules" {
  description = "Map of custom allocation rules to create. Each key is a logical name. Note: rule_name is immutable — changing it forces resource replacement."
  type = map(object({
    rule_name     = string
    enabled       = bool
    providernames = list(string)
    costs_to_allocate = optional(list(object({
      condition = optional(string, null)
      tag       = optional(string, null)
      value     = optional(string, null)
      values    = optional(list(string), null)
    })), [])
    strategy = optional(object({
      allocated_by_tag_keys        = optional(list(string), null)
      evaluate_grouped_by_tag_keys = optional(list(string), null)
      granularity                  = optional(string, null)
      method                       = optional(string, null)
      allocated_by = optional(list(object({
        percentage = optional(number, null)
        allocated_tags = optional(list(object({
          key   = optional(string, null)
          value = optional(string, null)
        })), [])
      })), [])
      allocated_by_filters = optional(list(object({
        condition = optional(string, null)
        tag       = optional(string, null)
        value     = optional(string, null)
        values    = optional(list(string), null)
      })), [])
      based_on_costs = optional(list(object({
        condition = optional(string, null)
        tag       = optional(string, null)
        value     = optional(string, null)
        values    = optional(list(string), null)
      })), [])
      based_on_timeseries = optional(bool, null)
      evaluate_grouped_by_filters = optional(list(object({
        condition = optional(string, null)
        tag       = optional(string, null)
        value     = optional(string, null)
        values    = optional(list(string), null)
      })), [])
    }), null)
  }))
  default = {}
}

###########################
# Rule Order Variables
###########################

variable "enable_rule_order" {
  description = "Whether to manage the evaluation order of custom allocation rules via the datadog_custom_allocation_rules resource. Set to true to enable rule order management."
  type        = bool
  default     = false
}

variable "rule_order" {
  description = "Ordered list of custom allocation rule IDs that determines their evaluation sequence. Used when enable_rule_order is true. Obtain IDs from this module's ids output or from other rule sources."
  type        = list(string)
  default     = []
}

variable "override_ui_defined_resources" {
  description = "Whether to override rules created via the Datadog UI. When true, UI-defined rules not present in rule_order will be deleted and Terraform becomes the sole source of truth. When false, UI rules appended to the end of the order are preserved (rules inserted in the middle cause a plan-time error). Default is false."
  type        = bool
  default     = false
}
