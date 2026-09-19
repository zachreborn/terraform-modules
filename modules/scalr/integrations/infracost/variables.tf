###########################
# Resource Variables
###########################
variable "infracost_integrations" {
  description = <<-EOT
    Map of Scalr Infracost integrations keyed by a caller-supplied logical name. Each entry
    manages one `scalr_integration_infracost` resource, surfacing Infracost cost estimates on
    runs in the linked environments.

    Note: `api_key` is intentionally NOT a field of this object. Supply it via the sibling
    `infracost_api_keys` variable, keyed to the same logical name, so this variable (and any
    output derived from it) never needs to be marked sensitive. Every key in this map must have
    a matching key in var.infracost_api_keys.

    Fields:
      - name:         (Required) Name of the Infracost integration.
      - environments: (Optional) List of environments this integration is linked to. Use ["*"]
                       to allow in all environments.

    Example:
      infracost_integrations = {
        default = {
          name         = "infracost"
          environments = ["*"]
        }
      }
      infracost_api_keys = {
        default = var.infracost_api_key
      }
  EOT
  type = map(object({
    name         = string
    environments = optional(set(string))
  }))
  default  = {}
  nullable = false
}

variable "infracost_api_keys" {
  description = "Map of Infracost API keys, keyed to match the same logical name used in var.infracost_integrations. Sensitive."
  type        = map(string)
  sensitive   = true
  default     = {}
  nullable    = false
}
