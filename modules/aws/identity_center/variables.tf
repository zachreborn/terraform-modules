variable "groups" {
  description = "(Required) The list of groups to create."
  type = map(object({
    display_name = string           # (Required) The friendly name to identify the group.
    description  = optional(string) # (Optional) The description of the group.
  }))
  # Example
  # groups = {
  #   "Administrators" = {
  #     display_name = "Administrators"
  #     description  = "The group for the administrators of the application."
  #   },
  #   "Users" = {
  #     display_name = "Users"
  #     # description is optional and may be omitted
  #   }
  # }
}

variable "permission_sets" {
  description = <<-EOT
    (Optional) Map of AWS Identity Center permission sets to create, keyed by a caller-chosen logical
    name (e.g. "admins"). Each entry is wired to the modules/aws/identity_center/permission_set
    submodule -- see that submodule's README for the full field reference. Group associations can be
    expressed two ways:
      - groups:     Pre-existing group display names, resolved via the permission_set submodule's own
                     aws_identitystore_group data source. Use this for groups that are not managed by
                     this same identity_center module call.
      - group_keys: Keys into this module's own var.groups map. Resolved directly from the group
                     resource created by this same module call (a resource attribute, never a data
                     source lookup), so a brand-new group and its permission set can be created
                     together in a single apply -- this is the fix for the eager-lookup failure
                     described in issue #456. Every entry must exist in var.groups.
    A permission set with no group associations at all (policy-only) is a legitimate configuration and
    is not rejected, matching the permission_set submodule's own behavior.
  EOT
  type = map(object({
    name                             = optional(string)           # (Optional) Defaults to the map key when unset.
    description                      = optional(string)           # (Optional) The description of the permission set.
    groups                           = optional(list(string), []) # (Optional) Pre-existing group display names.
    group_keys                       = optional(list(string), []) # (Optional) Keys into this module's own var.groups.
    customer_managed_iam_policy_name = optional(string)           # (Optional) See permission_set submodule.
    customer_managed_iam_policy_path = optional(string, "/")      # (Optional) See permission_set submodule.
    inline_policy                    = optional(string)           # (Optional) See permission_set submodule.
    managed_policy_arns              = optional(list(string), []) # (Optional) See permission_set submodule.
    relay_state                      = optional(string)           # (Optional) See permission_set submodule.
    session_duration                 = optional(string, "PT1H")   # (Optional) See permission_set submodule.
    target_accounts                  = set(string)                # (Required) AWS account IDs to assign the permission set to.
    tags                             = optional(map(string), {})  # (Optional) Additional tags for this permission set.
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for k, v in var.permission_sets : v != null
    ])
    error_message = "Each permission_sets entry must be an object that sets at least target_accounts; bare/null entries are not supported."
  }
}

variable "users" {
  description = "(Required) The list of users to create."
  type = map(object({
    given_name  = string # (Required) The given name of the user.
    family_name = string # (Required) The family name of the user.
    user_name   = string # (Required) The username of the user.

    honorific_prefix = optional(string) # (Optional) The honorific prefix of the user.
    honorific_suffix = optional(string) # (Optional) The honorific suffix of the user.
    middle_name      = optional(string) # (Optional) The middle name of the user.
    nickname         = optional(string) # (Optional) The nickname of the user.

    email                   = optional(string) # (Optional) The email address of the user.
    email_is_primary        = optional(bool)   # (Optional) Indicates whether the email address is the primary email address of the user.
    email_type              = optional(string) # (Optional) The type of the email address of the user.
    phone_number            = optional(string) # (Optional) The phone number of the user.
    phone_number_is_primary = optional(bool)   # (Optional) Indicates whether the phone number is the primary phone number of the user.
    phone_number_type       = optional(string) # (Optional) The type of the phone number of the user.

    preferred_language = optional(string) # (Optional) The user's preferred language.
    timezone           = optional(string) # (Optional) The user's time zone.
    title              = optional(string) # (Optional) The user's title.
    user_type          = optional(string) # (Optional) The type of the user.

    groups = optional(list(string)) # (Optional) The list of groups the user belongs to.
  }))
  # Example
  # users = {
  #   "John Hill" = {
  #     given_name       = "John"
  #     family_name      = "Hill"
  #     user_name        = "john.hill@example.com"
  #     email            = "john.hill@example.com"
  #     email_is_primary = "true"
  #     groups           = ["Administrators"]
  #   }
  # }
}
