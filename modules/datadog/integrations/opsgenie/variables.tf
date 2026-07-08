###########################
# Resource Variables
###########################
variable "service_objects" {
  description = "Map of Opsgenie service objects keyed by a logical name. Each entry creates one Datadog - Opsgenie service integration. The opsgenie_api_key is sensitive."
  type = map(object({
    name             = string
    opsgenie_api_key = string
    region           = string
    custom_url       = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.service_objects : contains(["us", "eu", "custom"], v.region)
    ])
    error_message = "region must be one of: us, eu, custom."
  }
}
