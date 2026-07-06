###########################
# Resource Variables
###########################
variable "webhooks" {
  description = "Map of Datadog webhooks keyed by a logical name. Each entry creates one webhook that Datadog can call when a monitor alert triggers."
  type = map(object({
    name           = string
    url            = string
    custom_headers = optional(string)
    encode_as      = optional(string)
    payload        = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.webhooks : v.encode_as == null || contains(["json", "form"], v.encode_as)
    ])
    error_message = "encode_as must be one of: json, form."
  }
}

variable "webhook_custom_variables" {
  description = "Map of Datadog webhook custom variables keyed by a logical name. Each entry creates one reusable variable that can be referenced in webhook URLs and payloads. The value is sensitive."
  type = map(object({
    name      = string
    value     = string
    is_secret = bool
  }))
  default = {}
}
