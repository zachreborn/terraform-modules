###########################
# Resource Variables
###########################
variable "provider_configuration_defaults" {
  description = <<-EOT
    Map of scalr_provider_configuration_default resources to create, keyed by a caller-chosen
    logical name. Each entry marks a provider configuration as the default for an environment.
    Fields:
      - environment_id:            (Required) ID of the environment, in the format "env-<RANDOM STRING>".
      - provider_configuration_id: (Required) ID of the provider configuration, in the format "pcfg-<RANDOM STRING>".

    Note: to make a provider configuration default, it must already be shared with the specified
    environment -- see the `environments` attribute of scalr_provider_configuration.
  EOT
  type = map(object({
    environment_id            = string
    provider_configuration_id = string
  }))
  default = {}
}
