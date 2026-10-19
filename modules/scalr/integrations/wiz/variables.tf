###########################
# Resource Variables
###########################
variable "wiz_integrations" {
  description = <<-EOT
    Map of Scalr Wiz integrations keyed by a caller-chosen logical name. Each entry manages one
    `scalr_wiz_integration` resource, which lets Scalr run `wizcli` IaC scans as part of a run.
    The sensitive Wiz service-account client secret for each entry is intentionally NOT part of
    this variable -- see var.wiz_client_secrets. Keeping it out of this map lets
    var.wiz_integrations remain non-sensitive, which is required because it is this module's
    for_each source (OpenTofu/Terraform disallow for_each over a sensitive collection).

    Fields:
      - name:              (Required) Name of the Wiz integration. Must not be blank and must be at
                            most 128 characters.
      - client_id:         (Required) Wiz service-account client ID. Must not be blank and must be
                            at most 255 characters.
      - default_policies:  (Optional) Set of Wiz CI/CD policy names passed to `wizcli` as
                            `--policies`, one set element per policy. Elements must not be blank.
      - default_scan_name: (Optional) Default scan name passed to `wizcli` as `--name`. When unset,
                            scans are named "{workspace}-{run}". Must not be blank and must be at
                            most 255 characters.
      - endpoint_mode:     (Optional) Wiz tenant region: the commercial, GovCloud, or FedRAMP
                            auth/API host. Valid values are "commercial", "govcloud", and
                            "fedramp". Defaults to "commercial".
      - autofail:          (Optional) Block the run when the Wiz scan fails or cannot run. When
                            false, Wiz failures are reported in the following Scalr policy check
                            and do not block the Wiz stage. Defaults to false.
      - environments:      (Optional) Set of environment IDs (env-<RANDOM STRING>) the integration
                            is linked to. Use ["*"] to allow it in all current and future
                            environments; "*" must then be the only element. When unset, the
                            integration is created without environment links and the provider
                            does not manage them afterwards.

    Example:
      wiz_integrations = {
        iac_scanning = {
          name             = "wiz"
          client_id        = "svc-account-client-id"
          default_policies = ["Default IaC policy"]
          endpoint_mode    = "commercial"
          autofail         = false
          environments     = ["env-xxxxxxxxxx"]
        }
      }
  EOT
  type = map(object({
    name              = string
    client_id         = string
    default_policies  = optional(set(string))
    default_scan_name = optional(string)
    endpoint_mode     = optional(string, "commercial")
    autofail          = optional(bool, false)
    environments      = optional(set(string))
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.wiz_integrations : trimspace(value.name) != "" && length(value.name) <= 128
    ])
    error_message = "Each wiz_integrations entry's name must not be blank and must be at most 128 characters."
  }

  validation {
    condition = alltrue([
      for key, value in var.wiz_integrations : trimspace(value.client_id) != "" && length(value.client_id) <= 255
    ])
    error_message = "Each wiz_integrations entry's client_id must not be blank and must be at most 255 characters."
  }

  validation {
    condition = alltrue([
      for key, value in var.wiz_integrations : value.default_scan_name == null ? true : (trimspace(value.default_scan_name) != "" && length(value.default_scan_name) <= 255)
    ])
    error_message = "Each wiz_integrations entry's default_scan_name, when set, must not be blank and must be at most 255 characters."
  }

  validation {
    condition = alltrue([
      for key, value in var.wiz_integrations : value.default_policies == null ? true : alltrue([for policy in value.default_policies : trimspace(policy) != ""])
    ])
    error_message = "Each wiz_integrations entry's default_policies elements must not be blank."
  }

  validation {
    condition = alltrue([
      for key, value in var.wiz_integrations : contains(["commercial", "govcloud", "fedramp"], value.endpoint_mode)
    ])
    error_message = "Each wiz_integrations entry's endpoint_mode must be one of 'commercial', 'govcloud', or 'fedramp'."
  }

  validation {
    condition = alltrue([
      for key, value in var.wiz_integrations : value.environments == null ? true : alltrue([for environment in value.environments : trimspace(environment) != ""])
    ])
    error_message = "Each wiz_integrations entry's environments elements must not be blank."
  }

  # The provider only treats a lone "*" as "all environments"; mixing it with explicit IDs would be
  # sent to the API as an (invalid) environment ID.
  validation {
    condition = alltrue([
      for key, value in var.wiz_integrations : value.environments == null ? true : (!contains(value.environments, "*") || length(value.environments) == 1)
    ])
    error_message = "When a wiz_integrations entry's environments contains \"*\" (all environments), \"*\" must be the only element."
  }
}

variable "wiz_client_secrets" {
  description = <<-EOT
    Map of sensitive Wiz service-account client secrets for var.wiz_integrations, keyed by the same
    logical key. Kept in a separate, wholly `sensitive = true` variable so that
    var.wiz_integrations itself can remain non-sensitive (required, since it is the for_each source
    for scalr_wiz_integration.this). Every key in var.wiz_integrations must have a non-empty entry
    here (at most 512 characters), because the underlying provider requires a client secret for
    every integration. Entries without a matching integration are ignored.

    Example:
      wiz_client_secrets = {
        iac_scanning = var.wiz_client_secret
      }
  EOT
  type        = map(string)
  default     = {}
  nullable    = false
  sensitive   = true

  # Cross-variable validation (references var.wiz_integrations) requires OpenTofu/Terraform 1.9+.
  validation {
    condition = alltrue([
      for key in keys(var.wiz_integrations) : contains(nonsensitive(keys(var.wiz_client_secrets)), key)
    ])
    error_message = "Every key in wiz_integrations needs a matching entry in wiz_client_secrets. Missing entries for: ${join(", ", [for key in keys(var.wiz_integrations) : key if !contains(nonsensitive(keys(var.wiz_client_secrets)), key)])}."
  }

  validation {
    condition = alltrue([
      for key, value in var.wiz_client_secrets : try(trimspace(value) != "" && length(value) <= 512, false)
    ])
    error_message = "Each wiz_client_secrets value must be a non-empty string of at most 512 characters; null, empty, and whitespace-only client secrets are rejected."
  }
}
