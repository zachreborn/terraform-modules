###########################
# Resource Variables
###########################
variable "tenant_based_handles" {
  description = "Map of Microsoft Teams tenant-based handles keyed by a logical name. Each entry creates one tenant-based notification handle for use in Datadog monitors and alerts."
  type = map(object({
    name         = string
    tenant_name  = string
    team_name    = string
    channel_name = string
  }))
  default = {}
}

variable "workflows_webhook_handles" {
  description = "Map of Microsoft Teams Workflows webhook handles keyed by a logical name. Each entry creates one Microsoft Workflows webhook handle. The url is sensitive."
  type = map(object({
    name = string
    url  = string
  }))
  default = {}
}
