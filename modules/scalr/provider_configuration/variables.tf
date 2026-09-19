###########################
# Resource Variables
###########################
variable "provider_configurations" {
  description = <<-EOT
    Map of Scalr Provider Configurations (scalr_provider_configuration) to create, keyed by a
    caller-chosen logical name. Each entry must set exactly one of the aws / azurerm / google /
    scalr / custom blocks. Fields:
      - name:                    (Optional) Name of the provider configuration, unique per account.
                                Defaults to the entry's map key.
      - account_id:               (Optional) The account that owns the object, in the format "acc-<RANDOM STRING>".
      - apply_only:               (Optional) When enabled, the provider configuration is used only during the
                                apply phase of a run. Currently supported for AWS only. Set only at creation time.
      - environments:             (Optional) Set of environment IDs the configuration is shared to. Use ["*"] to
                                share with all environments.
      - export_shell_variables:   (Optional) Export provider variables into the run environment. Available for
                                built-in (Scalr, AWS, AzureRM, Google) providers only.
      - owners:                   (Optional) Set of team IDs the provider configuration belongs to.
      - tag_ids:                  (Optional) Set of tag IDs associated with the provider configuration.
      - aws:                      (Optional) AWS provider settings. See below.
      - azurerm:                  (Optional) AzureRM provider settings. See below.
      - google:                   (Optional) Google provider settings. See below.
      - scalr:                    (Optional) Scalr provider settings. See below.
      - custom:                   (Optional) Settings for a provider without built-in Scalr support. See below.

    aws fields:
      - credentials_type:    (Required) One of "access_keys", "role_delegation", "oidc".
      - access_key:          (Optional) AWS access key. Required with "access_keys".
      - account_type:        (Optional) One of "regular", "gov-cloud", "cn-cloud".
      - audience:            (Optional) The "aud" claim value for the identity token. Required with "oidc".
      - credentials_source:  (Optional) One of "Ec2InstanceMetadata", "EcsContainer". Used with "role_delegation"
                             and "aws_service" trusted_entity_type.
      - external_id:         (Optional) External ID for assuming the role. Required with "role_delegation" and
                             "aws_account" trusted_entity_type.
      - role_arn:            (Optional) ARN of the IAM role to assume. Required with "role_delegation"/"oidc".
      - trusted_entity_type: (Optional) One of "aws_account", "aws_service". Required with "role_delegation".
      - default_tags:        (Optional) { tags = map(string), strategy = "skip"|"update" }.
      - secret_key:          Sensitive -- supplied via var.provider_configuration_secrets[<key>].aws_secret_key,
                             not here. Required with "access_keys".

    azurerm fields:
      - client_id:       (Required) The Client ID to use.
      - tenant_id:       (Required) The Tenant ID to use.
      - audience:        (Optional) The "aud" claim value for the identity token. Required with auth_type "oidc".
      - auth_type:       (Optional) One of "client-secrets" (default), "oidc".
      - subscription_id: (Optional) The Subscription ID to use.
      - client_secret:   Sensitive -- supplied via var.provider_configuration_secrets[<key>].azurerm_client_secret,
                         not here. Required when auth_type is "client-secrets".

    google fields:
      - auth_type:              (Optional) One of "service-account-key" (default), "oidc".
      - project:                (Optional) The default project ID to manage resources in.
      - service_account_email:  (Optional) Required when auth_type is "oidc".
      - use_default_project:    (Optional) Whether the project a credential is created in is used by default.
      - workload_provider_name: (Optional) Required when auth_type is "oidc".
      - default_labels:         (Optional) { labels = map(string), strategy = "skip"|"update" }.
      - credentials:            Sensitive -- supplied via var.provider_configuration_secrets[<key>].google_credentials,
                                not here. Required when auth_type is "service-account-key".

    scalr fields:
      - hostname: (Required) The Scalr hostname to use.
      - token:    Sensitive -- supplied via var.provider_configuration_secrets[<key>].scalr_token, not here.

    custom fields:
      - provider_name: (Required) The name of the Terraform/OpenTofu provider, e.g. "kubernetes".
      - arguments:      (Required, min 1) List of { name, value, description, hcl, sensitive }. When an
                        argument's `sensitive` is true, its `value` here is ignored; supply the real value via
                        var.provider_configuration_secrets[<key>].custom_argument_values[<argument name>] instead.

    Sensitive credential fields are intentionally NOT part of this variable -- see
    var.provider_configuration_secrets. Keeping them out of this map lets var.provider_configurations
    remain non-sensitive, which is required because it is this module's for_each source (OpenTofu/
    Terraform disallow for_each over a sensitive collection).
  EOT
  type = map(object({
    name                   = optional(string)
    account_id             = optional(string)
    apply_only             = optional(bool, false)
    environments           = optional(set(string))
    export_shell_variables = optional(bool, false)
    owners                 = optional(set(string))
    tag_ids                = optional(set(string))

    aws = optional(object({
      credentials_type    = string
      access_key          = optional(string)
      account_type        = optional(string)
      audience            = optional(string)
      credentials_source  = optional(string)
      external_id         = optional(string)
      role_arn            = optional(string)
      trusted_entity_type = optional(string)
      default_tags = optional(object({
        tags     = optional(map(string))
        strategy = optional(string)
      }))
    }))

    azurerm = optional(object({
      client_id       = string
      tenant_id       = string
      audience        = optional(string)
      auth_type       = optional(string, "client-secrets")
      subscription_id = optional(string)
    }))

    google = optional(object({
      auth_type              = optional(string, "service-account-key")
      project                = optional(string)
      service_account_email  = optional(string)
      use_default_project    = optional(bool)
      workload_provider_name = optional(string)
      default_labels = optional(object({
        labels   = optional(map(string))
        strategy = optional(string)
      }))
    }))

    scalr = optional(object({
      hostname = string
    }))

    custom = optional(object({
      provider_name = string
      arguments = optional(list(object({
        name        = string
        value       = optional(string)
        description = optional(string)
        hcl         = optional(bool, false)
        sensitive   = optional(bool, false)
      })), [])
    }))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.provider_configurations : length(compact([
        v.aws != null ? "aws" : "",
        v.azurerm != null ? "azurerm" : "",
        v.google != null ? "google" : "",
        v.scalr != null ? "scalr" : "",
        v.custom != null ? "custom" : "",
      ])) == 1
    ])
    error_message = "Each provider_configurations entry must set exactly one of aws, azurerm, google, scalr, or custom."
  }

  validation {
    condition = alltrue([
      for k, v in var.provider_configurations : v.aws == null || contains(["access_keys", "role_delegation", "oidc"], v.aws.credentials_type)
    ])
    error_message = "Each provider_configurations aws.credentials_type must be one of \"access_keys\", \"role_delegation\", or \"oidc\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.provider_configurations : v.aws == null || v.aws.account_type == null || contains(["regular", "gov-cloud", "cn-cloud"], v.aws.account_type)
    ])
    error_message = "Each provider_configurations aws.account_type must be one of \"regular\", \"gov-cloud\", or \"cn-cloud\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.provider_configurations : v.aws == null || v.aws.trusted_entity_type == null || contains(["aws_account", "aws_service"], v.aws.trusted_entity_type)
    ])
    error_message = "Each provider_configurations aws.trusted_entity_type must be one of \"aws_account\" or \"aws_service\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.provider_configurations : v.azurerm == null || contains(["client-secrets", "oidc"], v.azurerm.auth_type)
    ])
    error_message = "Each provider_configurations azurerm.auth_type must be one of \"client-secrets\" or \"oidc\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.provider_configurations : v.google == null || contains(["service-account-key", "oidc"], v.google.auth_type)
    ])
    error_message = "Each provider_configurations google.auth_type must be one of \"service-account-key\" or \"oidc\"."
  }

  validation {
    condition = alltrue([
      for k, v in var.provider_configurations : v.custom == null || length(v.custom.arguments) >= 1
    ])
    error_message = "Each provider_configurations custom block must declare at least one argument."
  }
}

variable "provider_configuration_secrets" {
  description = <<-EOT
    Map of sensitive credential values for var.provider_configurations, keyed by the same logical
    key. Kept in a separate, wholly `sensitive = true` variable so that var.provider_configurations
    itself can remain non-sensitive (required, since it is the for_each source for
    scalr_provider_configuration.this). Populate only the field(s) relevant to the corresponding
    entry's provider block:
      - aws_secret_key:         scalr_provider_configuration.aws.secret_key
      - azurerm_client_secret:  scalr_provider_configuration.azurerm.client_secret
      - google_credentials:     scalr_provider_configuration.google.credentials
      - scalr_token:            scalr_provider_configuration.scalr.token
      - custom_argument_values: map of custom.argument name => sensitive value, for arguments whose
        `sensitive = true` in the corresponding var.provider_configurations[<key>].custom.arguments entry.
  EOT
  type = map(object({
    aws_secret_key         = optional(string)
    azurerm_client_secret  = optional(string)
    google_credentials     = optional(string)
    scalr_token            = optional(string)
    custom_argument_values = optional(map(string), {})
  }))
  sensitive = true
  default   = {}
}

variable "provider_configuration_defaults" {
  description = <<-EOT
    Map of scalr_provider_configuration_default resources to create via the companion ./default
    submodule, keyed by a caller-chosen logical name. Set exactly one of:
      - provider_configuration_key: The map key of an entry in var.provider_configurations whose ID
                                    is resolved internally by this module (composition wiring).
      - provider_configuration_id:  A literal, externally-managed provider configuration ID (format
                                    "pcfg-<RANDOM STRING>").
    Fields:
      - environment_id: (Required) ID of the environment, in the format "env-<RANDOM STRING>".
  EOT
  type = map(object({
    provider_configuration_key = optional(string)
    provider_configuration_id  = optional(string)
    environment_id             = string
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.provider_configuration_defaults : (v.provider_configuration_key != null) != (v.provider_configuration_id != null)
    ])
    error_message = "Each provider_configuration_defaults entry must set exactly one of provider_configuration_key or provider_configuration_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.provider_configuration_defaults : v.provider_configuration_key == null || contains(keys(var.provider_configurations), v.provider_configuration_key)
    ])
    error_message = "Each provider_configuration_defaults provider_configuration_key must reference an existing key in var.provider_configurations."
  }
}
