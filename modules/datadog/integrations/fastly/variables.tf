###########################
# Resource Variables
###########################
variable "fastly_accounts" {
  description = "Map of Fastly account integrations keyed by a logical name. Each entry registers one Fastly account with Datadog. The api_key is sensitive."
  type = map(object({
    name               = string
    api_key            = optional(string)
    api_key_wo         = optional(string)
    api_key_wo_version = optional(string)
  }))
  default = {}
}

variable "fastly_services" {
  description = "Map of Fastly service integrations keyed by a logical name. Each entry links one Fastly service to a registered Fastly account in Datadog."
  type = map(object({
    service_id = string
    account_id = optional(string)
    tags       = optional(set(string))
  }))
  default = {}
}
