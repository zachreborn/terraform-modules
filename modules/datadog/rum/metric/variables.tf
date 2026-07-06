###########################
# Resource Variables
###########################

variable "metrics" {
  description = "Map of RUM-based metrics to create, keyed by a logical name. Each entry maps to one datadog_rum_metric resource."
  type = map(object({
    name       = string
    event_type = string
    compute = optional(object({
      aggregation_type    = string
      include_percentiles = optional(bool, null)
      path                = optional(string, null)
    }), null)
    filter = optional(object({
      query = optional(string, null)
    }), null)
    group_by = optional(list(object({
      path     = optional(string, null)
      tag_name = optional(string, null)
    })), null)
    uniqueness = optional(object({
      when = optional(string, null)
    }), null)
  }))
  default = {}
}
