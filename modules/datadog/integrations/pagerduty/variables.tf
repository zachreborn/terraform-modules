###########################
# Resource Variables
###########################
variable "pagerduty_integrations" {
  description = "Map of PagerDuty integrations keyed by a logical name. Typically a single entry per Datadog org. Contains the api_token which is sensitive."
  type = map(object({
    subdomain = string
    api_token = optional(string)
    schedules = optional(list(string), [])
  }))
  default = {}
}

variable "service_objects" {
  description = "Map of PagerDuty service objects keyed by a logical name. Each entry links one PagerDuty service to Datadog. The service_key is sensitive."
  type = map(object({
    service_name = string
    service_key  = string
  }))
  default = {}
}
