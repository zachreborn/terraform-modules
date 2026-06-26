###########################
# Resource Variables
###########################

variable "retention_filters" {
  description = "Map of RUM retention filters to create, keyed by a logical name. Each entry maps to one datadog_rum_retention_filter resource."
  type = map(object({
    application_id = string
    name           = string
    event_type     = string
    sample_rate    = number
    enabled        = optional(bool, true)
    query          = optional(string, "")
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.retention_filters :
      contains(["action", "error", "long_task", "resource", "session", "view"], v.event_type)
    ])
    error_message = "event_type must be one of: action, error, long_task, resource, session, view."
  }

  validation {
    condition = alltrue([
      for k, v in var.retention_filters :
      v.sample_rate >= 0.1 && v.sample_rate <= 100
    ])
    error_message = "sample_rate must be between 0.1 and 100."
  }
}

variable "enable_filter_order" {
  description = "Whether to manage the retention filter order for a RUM application. When true, filter_order_application_id and filter_order_ids must be provided. This is a singleton resource per application — only one module instance per application should set this to true."
  type        = bool
  default     = false
}

variable "filter_order_application_id" {
  description = "RUM application ID for the retention filter order resource. Required when enable_filter_order is true."
  type        = string
  default     = null
}

variable "filter_order_ids" {
  description = "Ordered list of all retention filter IDs for the application. Required when enable_filter_order is true. Must include all filter IDs for the application, including the default filters created internally by Datadog (those with IDs prefixed by 'default'). The order of IDs in this list defines the evaluation order of the filters."
  type        = list(string)
  default     = []
}
