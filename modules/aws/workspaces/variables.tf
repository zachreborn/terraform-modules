############################################################
# Service Role
############################################################

variable "enable_service_role" {
  description = "(Optional) If true (the default), creates the account-wide workspaces_DefaultRole IAM role via the service_role submodule. Set to false when the role already exists (e.g. created by a prior call to this module in another region) -- WorkSpaces desktops still require the role to exist somewhere in the account."
  type        = bool
  default     = true
}

variable "service_role_name" {
  description = "(Optional) Name of the IAM role created when enable_service_role is true. Passed through to the service_role submodule's name field."
  type        = string
  default     = "workspaces_DefaultRole"
}

variable "enable_self_service_access" {
  description = "(Optional) If true (the default), additionally attaches the AmazonWorkSpacesSelfServiceAccess managed policy to the service role created when enable_service_role is true. Passed through to the service_role submodule, whose own default matches this one -- see that module's variable for the rationale (directories default restart_workspace = true, so the role needs this policy for that to actually work)."
  type        = bool
  default     = true
}

############################################################
# Directories
############################################################

variable "directories" {
  description = <<-EOT
    (Optional) Map of WorkSpaces directories to register, identical shape to modules/aws/workspaces/directory's
    own directories variable, including ip_group_keys: a list of keys into var.ip_groups, resolved through
    this module's own wiring (ip_group_id_lookup, wired to the ip_groups submodule's ids output) into literal
    IP group IDs and merged with any literal ip_group_ids also supplied -- this lets a single tofu apply of
    this module create IP groups and a directory that references them together. An invalid key surfaces as
    an error on the directory submodule's own precondition; see that module's README for the full field
    reference.
  EOT
  type = map(object({
    directory_id                    = optional(string)
    workspace_type                  = optional(string, "PERSONAL")
    subnet_ids                      = optional(list(string))
    ip_group_ids                    = optional(list(string), [])
    ip_group_keys                   = optional(list(string), [])
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
}

############################################################
# IP Access Control Groups
############################################################

variable "ip_groups" {
  description = "(Optional) Map of WorkSpaces IP access control groups to create, keyed by a caller-chosen logical name. Identical shape to modules/aws/workspaces/ip_group's own ip_groups variable. Referenced by var.directories entries via ip_group_keys."
  type = map(object({
    name        = optional(string)
    description = optional(string)
    rules = optional(list(object({
      source      = string
      description = optional(string)
    })), [])
    tags = optional(map(string), {})
  }))
  default = {}
}

############################################################
# Connection Aliases
############################################################

variable "connection_aliases" {
  description = "(Optional) Map of WorkSpaces connection aliases (cross-Region redirection FQDNs) to create, keyed by a caller-chosen logical name. Identical shape to modules/aws/workspaces/connection_alias's own connection_aliases variable."
  type = map(object({
    connection_string = string
    tags              = optional(map(string), {})
  }))
  default = {}
}

############################################################
# Desktops
############################################################

variable "workspaces" {
  description = <<-EOT
    (Optional) Map of WorkSpaces desktops to create, identical shape to modules/aws/workspaces/workspace's
    own workspaces variable, including directory_key: a key into var.directories, resolved through this
    module's own wiring (directory_id_lookup, wired to the directories submodule's ids output) into a
    literal directory ID -- this lets a single tofu apply of this module create a directory and the desktops
    that attach to it together. Entries that instead target an already-existing, externally-managed directory
    should keep using the literal directory_id field. An invalid directory_key surfaces as an error on the
    workspace submodule's own precondition; see that module's README for the full field reference.
  EOT
  type = map(object({
    directory_id  = optional(string)
    directory_key = optional(string)
    user_name     = string
    bundle_id     = optional(string)
    bundle_name   = optional(string)
    bundle_owner  = optional(string, "AMAZON")

    root_volume_encryption_enabled = optional(bool, true)
    user_volume_encryption_enabled = optional(bool, true)
    volume_encryption_key          = optional(string)

    workspace_properties = optional(object({
      compute_type_name                         = optional(string, "STANDARD")
      root_volume_size_gib                      = optional(number, 80)
      running_mode                              = optional(string, "AUTO_STOP")
      running_mode_auto_stop_timeout_in_minutes = optional(number, 60)
      user_volume_size_gib                      = optional(number, 50)
    }), {})

    tags = optional(map(string), {})
  }))
  default = {}
}

variable "enable_default_kms_key" {
  description = "(Optional) If true (the default), passed through to the workspace submodule so it creates one shared AWS KMS customer-managed key for every workspaces entry that omits volume_encryption_key. Set to false to require every entry to supply its own volume_encryption_key."
  type        = bool
  default     = true
}

variable "kms_key_alias_prefix" {
  description = "(Optional) Passed through to the workspace submodule's kms_key_alias_prefix field. Ignored when enable_default_kms_key is false or no entry needs the shared key. See that submodule's variable for the exact alias-naming behavior (a generated suffix is appended to this prefix)."
  type        = string
  default     = "workspaces"
}

############################################################
# General Variables
############################################################

variable "tags" {
  description = "(Optional) A mapping of tags applied to every resource created by this module (the service role, IP groups, directories, connection aliases, desktops, and the shared default KMS key), merged with each entry's optional per-resource tags."
  type        = map(string)
  default     = {}
}
