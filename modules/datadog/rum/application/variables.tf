###########################
# Resource Variables
###########################

variable "applications" {
  description = "Map of RUM applications to create, keyed by a logical name. Each entry maps to one datadog_rum_application resource."
  type = map(object({
    name                              = string
    type                              = optional(string, "browser")
    rum_event_processing_state        = optional(string, null)
    product_analytics_retention_state = optional(string, null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.applications :
      contains(["browser", "ios", "android", "react-native", "flutter"], v.type)
    ])
    error_message = "type must be one of: browser, ios, android, react-native, flutter."
  }

  validation {
    condition = alltrue([
      for k, v in var.applications :
      v.rum_event_processing_state == null || contains(["ALL", "ERROR_FOCUSED_MODE", "NONE"], v.rum_event_processing_state)
    ])
    error_message = "rum_event_processing_state must be one of: ALL, ERROR_FOCUSED_MODE, NONE."
  }

  validation {
    condition = alltrue([
      for k, v in var.applications :
      v.product_analytics_retention_state == null || contains(["MAX", "NONE"], v.product_analytics_retention_state)
    ])
    error_message = "product_analytics_retention_state must be one of: MAX, NONE."
  }
}
