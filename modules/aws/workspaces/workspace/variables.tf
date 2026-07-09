variable "workspaces" {
  description = <<-EOT
    (Optional) Map of WorkSpaces desktops to create, keyed by a caller-chosen logical name (e.g. a username).
    Each entry must set user_name, exactly one of directory_id or directory_key, and exactly one of bundle_id
    or bundle_name to select the WorkSpaces bundle -- this is how a given desktop is provisioned as Windows
    vs. Linux, since the bundle determines the operating system. When bundle_id is unset, it is resolved via
    an aws_workspaces_bundle data source lookup using bundle_name/bundle_owner. When directory_id is unset,
    it is resolved via directory_key, a key into var.directory_id_lookup.
    Fields:
      - directory_id:                   (Optional) ID of the WorkSpaces directory this desktop belongs to,
                                         e.g. the `ids` output of modules/aws/workspaces/directory. Each entry
                                         must set exactly one of directory_id or directory_key.
      - directory_key:                  (Optional) Key into var.directory_id_lookup, resolved into a literal
                                         directory_id. Conflicts with directory_id.
      - user_name:                      (Required) Username of the directory user this desktop is assigned
                                         to. Must already exist in the directory.
      - bundle_id:                      (Optional) ID of the WorkSpaces bundle. Conflicts with bundle_name.
      - bundle_name:                    (Optional) Name of the WorkSpaces bundle to look up (e.g. an Amazon
                                         Linux bundle name for a Linux desktop, or a Windows 10/11 bundle name
                                         for a Windows desktop). Conflicts with bundle_id.
      - bundle_owner:                   (Optional) Owner of the bundle referenced by bundle_name. Defaults to
                                         "AMAZON", which resolves an Amazon-provided bundle. Set this to your
                                         own AWS account ID instead to resolve a caller-owned custom bundle.
      - root_volume_encryption_enabled: (Optional) Whether the root volume is encrypted. Defaults to true.
      - user_volume_encryption_enabled: (Optional) Whether the user volume is encrypted. Defaults to true.
      - volume_encryption_key:          (Optional) ARN of the KMS key used to encrypt this desktop's volumes.
                                         When unset and var.enable_default_kms_key is true (the default), the
                                         shared KMS key this module creates is used instead.
      - workspace_properties:           (Optional) Compute/running-mode settings. See nested fields below.
      - tags:                           (Optional) Additional tags for this desktop, merged with var.tags.
    workspace_properties fields:
      - compute_type_name:                        (Optional) Defaults to "STANDARD".
      - root_volume_size_gib:                     (Optional) Defaults to 80.
      - running_mode:                             (Optional) AUTO_STOP or ALWAYS_ON. Defaults to "AUTO_STOP"
                                                   for cost control.
      - running_mode_auto_stop_timeout_in_minutes: (Optional) Defaults to 60.
      - user_volume_size_gib:                      (Optional) Defaults to 50.
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

  validation {
    condition = alltrue([
      for k, v in var.workspaces : (v.directory_id != null) != (v.directory_key != null)
    ])
    error_message = "Each workspaces entry must set exactly one of directory_id or directory_key."
  }

  validation {
    condition = alltrue([
      for k, v in var.workspaces : (v.bundle_id != null) != (v.bundle_name != null)
    ])
    error_message = "Each workspaces entry must set exactly one of bundle_id or bundle_name."
  }

  validation {
    condition = alltrue([
      for k, v in var.workspaces :
      v.workspace_properties.running_mode == null || contains(["AUTO_STOP", "ALWAYS_ON"], v.workspace_properties.running_mode)
    ])
    error_message = "Each workspaces entry's workspace_properties.running_mode must be AUTO_STOP or ALWAYS_ON."
  }
}

variable "directory_id_lookup" {
  description = "(Optional) Map of WorkSpaces directory IDs keyed by logical name, e.g. the `ids` output of modules/aws/workspaces/directory. Referenced by each workspaces entry's directory_key."
  type        = map(string)
  default     = {}
}

variable "enable_default_kms_key" {
  type        = bool
  description = "(Optional) If true (the default) and an entry in var.workspaces omits volume_encryption_key, this module creates one shared AWS KMS customer-managed key (via modules/aws/kms) aliased alias/<kms_key_alias> and uses its ARN as that entry's volume_encryption_key. Set to false to require every entry to supply its own volume_encryption_key, or to rely on the AWS-managed alias/aws/workspaces key by leaving volume_encryption_key null."
  default     = true
}

variable "kms_key_alias" {
  type        = string
  description = "(Optional) Alias suffix (passed as name_prefix to modules/aws/kms) for the shared default KMS key created when enable_default_kms_key is true and at least one entry needs it. Ignored otherwise."
  default     = "workspaces"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to every desktop and to the shared default KMS key (if created), merged with each entry's optional per-desktop tags."
  default     = {}
}
