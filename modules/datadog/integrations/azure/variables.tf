###########################
# Resource Variables
###########################
variable "azure_integrations" {
  description = "Map of Azure integrations keyed by a logical name. Each entry creates one Datadog - Azure subscription integration. The client_secret is sensitive."
  type = map(object({
    tenant_name                 = string
    client_id                   = string
    client_secret               = optional(string)
    secretless_auth_enabled     = optional(bool, false)
    automute                    = optional(bool, false)
    cspm_enabled                = optional(bool, false)
    custom_metrics_enabled      = optional(bool, false)
    metrics_enabled             = optional(bool, true)
    metrics_enabled_default     = optional(bool, true)
    usage_metrics_enabled       = optional(bool, true)
    resource_collection_enabled = optional(bool)
    host_filters                = optional(string, "")
    app_service_plan_filters    = optional(string, "")
    container_app_filters       = optional(string, "")
    resource_provider_configs = optional(list(object({
      namespace       = optional(string)
      metrics_enabled = optional(bool)
    })))
  }))
  default = {}
}
