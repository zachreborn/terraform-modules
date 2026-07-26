###########################
# Resource Variables
###########################
variable "checkov_integrations" {
  description = <<-EOT
    Map of Scalr Checkov integrations keyed by a caller-supplied logical name. Each entry
    manages one `scalr_checkov_integration` resource, running Checkov static analysis against
    runs in the linked environments.

    Fields:
      - name:                    (Required) Name of the Checkov integration.
      - cli_args:                (Optional) CLI parameters to be passed to the checkov command.
      - environments:            (Optional) List of environments this integration is linked to.
                                  Use ["*"] to allow in all environments.
      - external_checks_enabled: (Optional, default false) Whether external (custom) Checkov
                                  checks from a VCS repository should be enabled.
      - vcs_provider_id:         (Required if external_checks_enabled is true) ID of the VCS
                                  provider, in the format "vcs-<RANDOM STRING>".
      - vcs_repo:                (Required if external_checks_enabled is true) Settings for the
                                  Checkov integration's VCS repository.
          - identifier: (Required) Reference to the VCS repository (format varies by VCS type).
          - branch:     (Optional) Branch the custom checks are associated with.
          - path:       (Optional) Sub-directory of the repository where checks are stored.
      - version:                 (Optional) Version of the Checkov integration to use.

    Example:
      checkov_integrations = {
        default = {
          name         = "my-checkov-integration"
          environments = ["*"]
          cli_args     = "--quiet"
        }
        custom_checks = {
          name                    = "custom-checks"
          external_checks_enabled = true
          vcs_provider_id         = "vcs-xxxxxxxxxx"
          vcs_repo = {
            identifier = "my-org/my-checkov-checks"
            branch     = "main"
          }
        }
      }
  EOT
  type = map(object({
    name                    = string
    cli_args                = optional(string)
    environments            = optional(set(string))
    external_checks_enabled = optional(bool, false)
    vcs_provider_id         = optional(string)
    vcs_repo = optional(object({
      identifier = string
      branch     = optional(string)
      path       = optional(string)
    }))
    version = optional(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.checkov_integrations : !value.external_checks_enabled || value.vcs_provider_id != null
    ])
    error_message = "Each checkov_integrations entry with external_checks_enabled = true must set vcs_provider_id."
  }

  validation {
    condition = alltrue([
      for key, value in var.checkov_integrations : !value.external_checks_enabled || value.vcs_repo != null
    ])
    error_message = "Each checkov_integrations entry with external_checks_enabled = true must set vcs_repo."
  }
}
