###########################
# Resource Variables
###########################
variable "datadog_integrations" {
  description = <<-EOT
    Map of Scalr Datadog integrations keyed by a caller-chosen logical name. Each entry manages
    one `scalr_datadog_integration` resource, which lets Scalr send run metrics and events to
    Datadog. The sensitive Datadog API key for each entry is intentionally NOT part of this
    variable -- see var.datadog_api_keys. Keeping it out of this map lets var.datadog_integrations
    remain non-sensitive, which is required because it is this module's for_each source
    (OpenTofu/Terraform disallow for_each over a sensitive collection).

    Fields:
      - name:           (Required) Name of the Datadog integration. Must not be blank and must be
                         at most 128 characters.
      - deployment_url: (Optional) URL of the Datadog site, for example
                         "https://us5.datadoghq.com". Must start with "https://" and must not
                         embed credentials. When unset, Scalr uses "https://api.datadoghq.com".

    Example:
      datadog_integrations = {
        primary = {
          name           = "datadog"
          deployment_url = "https://us5.datadoghq.com"
        }
      }
  EOT
  type = map(object({
    name           = string
    deployment_url = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.datadog_integrations : trimspace(value.name) != "" && length(value.name) <= 128
    ])
    error_message = "Each datadog_integrations entry's name must not be blank and must be at most 128 characters."
  }

  validation {
    condition = alltrue([
      for key, value in var.datadog_integrations : value.deployment_url == null ? true : can(regex("^https://[^/?#@\\s]+([/?#].*)?$", value.deployment_url))
    ])
    error_message = "Each datadog_integrations entry's deployment_url, when set, must start with 'https://' followed by a host (for example 'https://us5.datadoghq.com') and must not embed credentials."
  }
}

variable "datadog_api_keys" {
  description = <<-EOT
    Map of sensitive Datadog API keys for var.datadog_integrations, keyed by the same logical key.
    Kept in a separate, wholly `sensitive = true` variable so that var.datadog_integrations itself
    can remain non-sensitive (required, since it is the for_each source for
    scalr_datadog_integration.this). Every key in var.datadog_integrations must have a non-empty
    entry here, because the underlying provider requires an API key for every integration.
    Entries without a matching integration are ignored.

    Example:
      datadog_api_keys = {
        primary = var.datadog_api_key
      }
  EOT
  type        = map(string)
  default     = {}
  nullable    = false
  sensitive   = true

  # Cross-variable validation (references var.datadog_integrations) requires OpenTofu/Terraform 1.9+.
  validation {
    condition = alltrue([
      for key in keys(var.datadog_integrations) : contains(nonsensitive(keys(var.datadog_api_keys)), key)
    ])
    error_message = "Every key in datadog_integrations needs a matching entry in datadog_api_keys. Missing entries for: ${join(", ", [for key in keys(var.datadog_integrations) : key if !contains(nonsensitive(keys(var.datadog_api_keys)), key)])}."
  }

  validation {
    condition = alltrue([
      for key, value in var.datadog_api_keys : try(trimspace(value) != "", false)
    ])
    error_message = "Each datadog_api_keys value must be a non-empty string; null, empty, and whitespace-only API keys are rejected."
  }
}
