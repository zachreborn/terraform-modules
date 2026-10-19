###########################
# Resource Variables
###########################
variable "docker_integrations" {
  description = <<-EOT
    Map of Scalr Docker (OCI) registry integrations keyed by a caller-chosen logical name. Each
    entry manages one `scalr_docker_integration` resource, which stores registry credentials in
    Scalr. The integration is what an OCI-sourced `scalr_module` consumes through its
    `docker_integration_id`, and it can optionally inject the credentials into runs for direct
    `oci://` module access. The sensitive registry password for each entry is intentionally NOT
    part of this variable -- see var.docker_passwords. Keeping it out of this map lets
    var.docker_integrations remain non-sensitive, which is required because it is this module's
    for_each source (OpenTofu/Terraform disallow for_each over a sensitive collection).

    Fields:
      - name:               (Required) Name of the Docker integration. Must not be blank.
      - registry_url:       (Required) Registry URL, for example "https://ghcr.io". Must start with
                             "https://", include a host, and must not embed credentials. Only one
                             integration per registry host is allowed, so hosts must be unique
                             across entries. Redirecting URLs are rejected by Scalr.
      - username:           (Required) Registry username. Must not be blank.
      - export_credentials: (Optional) Whether to inject the credentials into plan and apply runs
                             for direct oci:// module access. Defaults to false.

    Example:
      docker_integrations = {
        ghcr = {
          name               = "ghcr"
          registry_url       = "https://ghcr.io"
          username           = "my-user"
          export_credentials = true
        }
      }
  EOT
  type = map(object({
    name               = string
    registry_url       = string
    username           = string
    export_credentials = optional(bool, false)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.docker_integrations : trimspace(value.name) != ""
    ])
    error_message = "Each docker_integrations entry's name must not be blank."
  }

  validation {
    condition = alltrue([
      for key, value in var.docker_integrations : trimspace(value.username) != ""
    ])
    error_message = "Each docker_integrations entry's username must not be blank."
  }

  validation {
    condition = alltrue([
      for key, value in var.docker_integrations : can(regex("^https://[^/?#@\\s]+([/?#].*)?$", value.registry_url))
    ])
    error_message = "Each docker_integrations entry's registry_url must start with 'https://' followed by a host (for example 'https://ghcr.io') and must not embed credentials."
  }

  # Scalr allows one integration per registry host. Hosts are compared case-insensitively and
  # without the default HTTPS port, mirroring how Scalr normalizes the URL (scheme + lowercase
  # host + non-default port). A URL that fails the https:// rule above falls back to its raw
  # value here so this rule never raises its own evaluation error.
  validation {
    condition = length(distinct([
      for key, value in var.docker_integrations : trimsuffix(lower(try(regex("^https://([^/?#\\s]+)", value.registry_url)[0], value.registry_url)), ":443")
    ])) == length(var.docker_integrations)
    error_message = "Each docker_integrations entry must use a unique registry host: Scalr allows only one Docker integration per registry host (compared case-insensitively, ignoring the default :443 port)."
  }
}

variable "docker_passwords" {
  description = <<-EOT
    Map of sensitive registry passwords or personal access tokens for var.docker_integrations,
    keyed by the same logical key. Kept in a separate, wholly `sensitive = true` variable so that
    var.docker_integrations itself can remain non-sensitive (required, since it is the for_each
    source for scalr_docker_integration.this). Every key in var.docker_integrations must have a
    non-empty entry here, because the underlying provider requires a password for every
    integration. Entries without a matching integration are ignored.

    Example:
      docker_passwords = {
        ghcr = var.ghcr_token
      }
  EOT
  type        = map(string)
  default     = {}
  nullable    = false
  sensitive   = true

  # Cross-variable validation (references var.docker_integrations) requires OpenTofu/Terraform 1.9+.
  validation {
    condition = alltrue([
      for key in keys(var.docker_integrations) : contains(nonsensitive(keys(var.docker_passwords)), key)
    ])
    error_message = "Every key in docker_integrations needs a matching entry in docker_passwords. Missing entries for: ${join(", ", [for key in keys(var.docker_integrations) : key if !contains(nonsensitive(keys(var.docker_passwords)), key)])}."
  }

  validation {
    condition = alltrue([
      for key, value in var.docker_passwords : try(trimspace(value) != "", false)
    ])
    error_message = "Each docker_passwords value must be a non-empty string; null, empty, and whitespace-only passwords are rejected."
  }
}
