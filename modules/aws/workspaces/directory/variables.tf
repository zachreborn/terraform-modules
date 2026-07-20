variable "directories" {
  description = <<-EOT
    (Optional) Map of WorkSpaces directories to register, keyed by a caller-chosen logical name.
    This module does not create the underlying AWS Directory Service directory -- point directory_id at a
    directory created by modules/aws/directory_service_simple_ad, modules/aws/directory_service_ad_connector,
    or modules/aws/directory_service_microsoftad (or an externally-managed one) for PERSONAL directories.
    Fields:
      - directory_id:                     (Required when workspace_type = PERSONAL) ID of an existing AWS
                                           Directory Service directory. Must be null when workspace_type =
                                           POOLS, since AWS generates the directory ID automatically in that
                                           case.
      - workspace_type:                   (Optional) PERSONAL or POOLS. Defaults to "PERSONAL".
      - subnet_ids:                       (Optional) Subnet IDs (2, across different AZs) where this
                                           directory resides.
      - ip_group_ids:                     (Optional) IDs of WorkSpaces IP access control groups to associate,
                                           e.g. the `ids` output of modules/aws/workspaces/ip_group. Defaults
                                           to [].
      - ip_group_keys:                    (Optional) Keys into var.ip_group_id_lookup, resolved into literal
                                           IP group IDs and merged with ip_group_ids above. Defaults to [].
      - region:                           (Optional) Region where this directory is managed. Defaults to the
                                           Region set in the provider configuration.
      - tenancy:                          (Optional) DEDICATED or SHARED.
      - workspace_directory_name:         (Required when workspace_type = POOLS) Name of the directory.
      - workspace_directory_description:  (Required when workspace_type = POOLS) Description of the directory.
      - user_identity_type:               (Required when workspace_type = POOLS) One of CUSTOMER_MANAGED,
                                           AWS_DIRECTORY_SERVICE, or AWS_IAM_IDENTITY_CENTER.
      - active_directory_config:          (Optional, POOLS only -- rejected for PERSONAL) Active Directory
                                           domain join settings. Fields: domain_name (Required),
                                           service_account_secret_arn (Required, ARN of a Secrets Manager
                                           secret holding the domain-join service account credentials).
      - certificate_based_auth_properties: (Optional) Certificate-based authentication (CBA) via an ACM
                                           Private CA, layered on top of saml_properties for smart-card /
                                           passwordless authentication. Fields: certificate_authority_arn
                                           (Optional; required when status = "ENABLED"), status (Optional,
                                           defaults to "DISABLED"). Enabling CBA also requires saml_properties
                                           to be enabled.
      - saml_properties:                  (Optional) External SAML 2.0 identity provider integration (e.g.
                                           Okta, Entra ID, an IAM Identity Center SAML application, or ADFS).
                                           Fields: relay_state_parameter_name (Optional, defaults to
                                           "RelayState"), status (Optional, defaults to "DISABLED"),
                                           user_access_url (Optional; required when status = "ENABLED").
      - self_service_permissions:         (Optional, PERSONAL only -- ignored/omitted for POOLS directories)
                                           Secure-by-default: only restart_workspace is enabled; every other
                                           self-service action is disabled unless explicitly turned on.
      - workspace_access_properties:      (Optional) Secure-by-default: denies the web browser and zero
                                           client device types to shrink egress channels, allows native OS
                                           clients (Windows, macOS, Linux, iOS, Android, ChromeOS).
      - workspace_creation_properties:    (Optional) Secure-by-default: enable_internet_access = false
                                           (desktops rely on VPC routing instead of a direct internet path),
                                           enable_maintenance_mode = true, user_enabled_as_local_administrator
                                           = false. For workspace_type = POOLS entries, enable_maintenance_mode
                                           and user_enabled_as_local_administrator are always forced to false
                                           regardless of this setting, since AWS rejects both when set for a
                                           POOLS directory; default_ou may only be set when
                                           active_directory_config is also set.
      - tags:                             (Optional) Additional tags for this directory, merged with var.tags.
  EOT
  type = map(object({
    directory_id                    = optional(string)
    workspace_type                  = optional(string, "PERSONAL")
    subnet_ids                      = optional(list(string))
    ip_group_ids                    = optional(list(string), [])
    ip_group_keys                   = optional(list(string), [])
    region                          = optional(string)
    tenancy                         = optional(string)
    workspace_directory_name        = optional(string)
    workspace_directory_description = optional(string)
    user_identity_type              = optional(string)

    active_directory_config = optional(object({
      domain_name                = string
      service_account_secret_arn = string
    }))

    certificate_based_auth_properties = optional(object({
      certificate_authority_arn = optional(string)
      status                    = optional(string, "DISABLED")
    }))

    saml_properties = optional(object({
      relay_state_parameter_name = optional(string, "RelayState")
      status                     = optional(string, "DISABLED")
      user_access_url            = optional(string)
    }))

    self_service_permissions = optional(object({
      change_compute_type  = optional(bool, false)
      increase_volume_size = optional(bool, false)
      rebuild_workspace    = optional(bool, false)
      restart_workspace    = optional(bool, true)
      switch_running_mode  = optional(bool, false)
    }), {})

    workspace_access_properties = optional(object({
      device_type_android    = optional(string, "ALLOW")
      device_type_chromeos   = optional(string, "ALLOW")
      device_type_ios        = optional(string, "ALLOW")
      device_type_linux      = optional(string, "ALLOW")
      device_type_osx        = optional(string, "ALLOW")
      device_type_web        = optional(string, "DENY")
      device_type_windows    = optional(string, "ALLOW")
      device_type_zeroclient = optional(string, "DENY")
    }), {})

    workspace_creation_properties = optional(object({
      custom_security_group_id            = optional(string)
      default_ou                          = optional(string)
      enable_internet_access              = optional(bool, false)
      enable_maintenance_mode             = optional(bool, true)
      user_enabled_as_local_administrator = optional(bool, false)
    }), {})

    tags = optional(map(string), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.directories : contains(["PERSONAL", "POOLS"], v.workspace_type)
    ])
    error_message = "Each directories entry's workspace_type must be PERSONAL or POOLS."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories :
      v.workspace_type != "POOLS" || (
        v.workspace_directory_name != null &&
        v.workspace_directory_description != null &&
        v.user_identity_type != null
      )
    ])
    error_message = "Each directories entry with workspace_type = POOLS must set workspace_directory_name, workspace_directory_description, and user_identity_type."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories : v.workspace_type != "POOLS" || v.directory_id == null
    ])
    error_message = "Each directories entry with workspace_type = POOLS must leave directory_id unset -- AWS generates it automatically."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories : v.workspace_type == "POOLS" || v.directory_id != null
    ])
    error_message = "Each directories entry with workspace_type = PERSONAL (the default) must set directory_id."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories :
      v.user_identity_type == null || contains(["CUSTOMER_MANAGED", "AWS_DIRECTORY_SERVICE", "AWS_IAM_IDENTITY_CENTER"], v.user_identity_type)
    ])
    error_message = "Each directories entry's user_identity_type must be one of CUSTOMER_MANAGED, AWS_DIRECTORY_SERVICE, or AWS_IAM_IDENTITY_CENTER."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories : v.tenancy == null || contains(["DEDICATED", "SHARED"], v.tenancy)
    ])
    error_message = "Each directories entry's tenancy must be DEDICATED or SHARED."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories :
      v.workspace_type != "POOLS" || v.workspace_creation_properties == null || v.active_directory_config != null || v.workspace_creation_properties.default_ou == null
    ])
    error_message = "Each directories entry with workspace_type = POOLS can only set workspace_creation_properties.default_ou when active_directory_config is also set (AWS rejects default_ou otherwise)."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories : v.workspace_type == "POOLS" || v.active_directory_config == null
    ])
    error_message = "Each directories entry's active_directory_config may only be set when workspace_type = POOLS -- AWS rejects it for PERSONAL directories."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories :
      v.saml_properties == null || v.saml_properties.status != "ENABLED" || v.saml_properties.user_access_url != null
    ])
    error_message = "Each directories entry's saml_properties.user_access_url is required when saml_properties.status = ENABLED."
  }

  validation {
    condition = alltrue([
      for k, v in var.directories :
      v.certificate_based_auth_properties == null || v.certificate_based_auth_properties.status != "ENABLED" || (
        v.certificate_based_auth_properties.certificate_authority_arn != null &&
        v.saml_properties != null && v.saml_properties.status == "ENABLED"
      )
    ])
    error_message = "Each directories entry's certificate_based_auth_properties requires certificate_authority_arn to be set and saml_properties.status = ENABLED when certificate_based_auth_properties.status = ENABLED."
  }
}

variable "ip_group_id_lookup" {
  description = "(Optional) Map of WorkSpaces IP access control group IDs keyed by logical name, e.g. the `ids` output of modules/aws/workspaces/ip_group. Referenced by each directories entry's ip_group_keys."
  type        = map(string)
  default     = {}
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to every directory, merged with each entry's optional per-directory tags."
  default     = {}
}
