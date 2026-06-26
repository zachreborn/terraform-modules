###########################
# Resource Variables
###########################
variable "event_bridges" {
  description = "Map of AWS EventBridge integrations keyed by a logical name. Each entry creates one Datadog - AWS EventBridge event source."
  type = map(object({
    account_id           = string
    event_generator_name = string
    region               = string
    create_event_bus     = optional(bool, true)
  }))
  default = {}
}
