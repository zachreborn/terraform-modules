###########################
# Resource Variables
###########################
variable "gcp_accounts" {
  description = "Map of Google Cloud Platform account integrations keyed by a logical name. Each entry creates one Datadog - GCP STS integration for a service account."
  type = map(object({
    client_email                          = string
    account_tags                          = optional(set(string))
    automute                              = optional(bool)
    is_cspm_enabled                       = optional(bool)
    is_global_location_enabled            = optional(bool)
    is_per_project_quota_enabled          = optional(bool)
    is_resource_change_collection_enabled = optional(bool)
    is_security_command_center_enabled    = optional(bool, false)
    resource_collection_enabled           = optional(bool)
    region_filter_configs                 = optional(set(string))
    metric_namespace_configs = optional(set(object({
      id       = optional(string)
      disabled = optional(bool)
      filters  = optional(set(string))
    })))
    monitored_resource_configs = optional(set(object({
      type    = optional(string)
      filters = optional(set(string))
    })))
  }))
  default = {}
}
