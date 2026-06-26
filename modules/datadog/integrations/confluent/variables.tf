###########################
# Resource Variables
###########################
variable "confluent_accounts" {
  description = "Map of Confluent Cloud account integrations keyed by a logical name. Each entry registers one Confluent account with Datadog. The api_key and api_secret are sensitive."
  type = map(object({
    api_key    = string
    api_secret = string
    tags       = optional(set(string))
  }))
  default = {}
}

variable "confluent_resources" {
  description = "Map of Confluent Cloud resource integrations keyed by a logical name. Each entry links one Confluent resource (Kafka cluster, connector, etc.) to a registered Confluent account."
  type = map(object({
    account_id            = string
    resource_id           = string
    resource_type         = optional(string)
    enable_custom_metrics = optional(bool, false)
    tags                  = optional(set(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.confluent_resources : v.resource_type == null || contains(["kafka", "connector", "ksql", "schema_registry"], v.resource_type)
    ])
    error_message = "resource_type must be one of: kafka, connector, ksql, schema_registry."
  }
}
