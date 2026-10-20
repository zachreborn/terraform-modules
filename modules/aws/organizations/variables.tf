############################################################
# Organization
############################################################

variable "organization" {
  description = <<-EOT
    (Optional) Configuration for the AWS Organization itself, passed through to the organization
    submodule (modules/aws/organizations/organization). Leave unset (the default, null) if the
    Organization already exists and is managed elsewhere -- this module then manages no
    aws_organizations_organization resource, and every organizational_units entry must set an explicit
    parent_id or parent_key (the automatic root-ID default described on organizational_units below
    requires organization to be set).
    Fields mirror modules/aws/organizations/organization's variables exactly; every field here is
    optional with no default of its own, so an unset field passes through as null and the organization
    submodule's own default takes over -- defaults stay single-sourced there.
  EOT
  type = object({
    allowed_regions                               = optional(list(string))
    attach_identity_center_scp                    = optional(bool)
    attach_leave_organization_scp                 = optional(bool)
    attach_region_scp                             = optional(bool)
    attach_root_access_key_scp                    = optional(bool)
    attach_root_actions_scp                       = optional(bool)
    attach_security_services_scp                  = optional(bool)
    aws_service_access_principals                 = optional(list(string))
    enable_identity_center_scp                    = optional(bool)
    enable_leave_organization_scp                 = optional(bool)
    enable_organization_backup                    = optional(bool)
    enable_region_scp                             = optional(bool)
    enable_root_access_key_scp                    = optional(bool)
    enable_root_actions_scp                       = optional(bool)
    enable_security_services_scp                  = optional(bool)
    enabled_features                              = optional(list(string))
    enabled_policy_types                          = optional(list(string))
    feature_set                                   = optional(string)
    identity_center_scp_description               = optional(string)
    identity_center_scp_name                      = optional(string)
    identity_center_scp_target_ids                = optional(list(string))
    leave_organization_scp_description            = optional(string)
    leave_organization_scp_name                   = optional(string)
    leave_organization_scp_target_ids             = optional(list(string))
    region_scp_description                        = optional(string)
    region_scp_exempted_actions                   = optional(list(string))
    region_scp_exempted_principal_arns            = optional(list(string))
    region_scp_name                               = optional(string)
    region_scp_target_ids                         = optional(list(string))
    root_access_key_scp_description               = optional(string)
    root_access_key_scp_name                      = optional(string)
    root_access_key_scp_target_ids                = optional(list(string))
    root_actions_scp_description                  = optional(string)
    root_actions_scp_exempted_actions             = optional(list(string))
    root_actions_scp_name                         = optional(string)
    root_actions_scp_target_ids                   = optional(list(string))
    security_services_scp_description             = optional(string)
    security_services_scp_exempted_principal_arns = optional(list(string))
    security_services_scp_name                    = optional(string)
    security_services_scp_target_ids              = optional(list(string))
    tags                                          = optional(map(string))
  })
  default = null
}

############################################################
# Organizational Units
############################################################

variable "organizational_units" {
  description = <<-EOT
    (Optional) Map of Organizational Units to create, identical shape to
    modules/aws/organizations/ou's organizational_units variable (including support for bare/null
    entries and parent_key nesting up to 4 levels). Any entry that sets neither parent_id nor parent_key
    is automatically attached to the managed Organization's root -- this requires var.organization to be
    set; otherwise such an entry fails validation in the ou submodule.
  EOT
  type = map(object({
    name       = optional(string)
    parent_id  = optional(string)
    parent_key = optional(string)
    tags       = optional(map(string), {})
  }))
  default = {}
}

############################################################
# Accounts
############################################################

variable "accounts" {
  description = <<-EOT
    (Optional) Map of AWS Organization member accounts to create, identical shape to
    modules/aws/organizations/account's accounts variable. organizational_unit_ids is wired
    automatically from the organizational_units created by this same module call, so there is no
    separate organizational_unit_ids input here.
    Note: iam_user_access_to_billing has no default here either, for the same reason it has none in the
    account submodule -- see that module's variable description for details.
    Tag keys and values (both each entry's tags map and the module-level tags variable below) must
    consist only of letters, numbers, spaces, and the characters + - = . _ : / @ (AWS Organizations'
    allowed tag character set). Tag keys must be non-empty; tag values may be empty.
  EOT
  type = map(object({
    name                       = optional(string)
    email                      = string
    parent_id                  = optional(string)
    parent_key                 = optional(string)
    iam_user_access_to_billing = optional(string)
    role_name                  = optional(string, "OrganizationAccountAccessRole")
    close_on_deletion          = optional(bool, false)
    tags                       = optional(map(string), {})
  }))
  default = {}

  # Duplicated from modules/aws/organizations/account/variables.tf's accounts validation (rather than
  # relying on the submodule alone) so the failure is reported against this caller-facing variable and
  # is referenceable from this module's own tests via expect_failures = [var.accounts] (issue #496).
  validation {
    condition = alltrue(flatten([
      for account_key, account in var.accounts : account != null ? [
        for tag_key, tag_value in account.tags : can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]+$", tag_key))
      ] : []
    ]))
    error_message = join(" ", concat(
      ["Each accounts entry's tags keys must consist only of letters, numbers, spaces, and the characters + - = . _ : / @ (AWS Organizations' allowed tag character set). Offending account_key.tag_key pairs:"],
      flatten([
        for account_key, account in var.accounts : account != null ? [
          for tag_key, tag_value in account.tags : "${account_key}.${tag_key}"
          if !can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]+$", tag_key))
        ] : []
      ])
    ))
  }

  validation {
    condition = alltrue(flatten([
      for account_key, account in var.accounts : account != null ? [
        for tag_key, tag_value in account.tags : can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]*$", tag_value))
      ] : []
    ]))
    error_message = join(" ", concat(
      ["Each accounts entry's tags values must consist only of letters, numbers, spaces, and the characters + - = . _ : / @ (AWS Organizations' allowed tag character set). Offending account_key.tag_key pairs (values omitted to avoid echoing long strings):"],
      flatten([
        for account_key, account in var.accounts : account != null ? [
          for tag_key, tag_value in account.tags : "${account_key}.${tag_key}"
          if !can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]*$", tag_value))
        ] : []
      ])
    ))
  }
}

############################################################
# Delegated Administrators
############################################################

variable "delegated_admins" {
  description = <<-EOT
    (Optional) Map of delegated administrator configurations to create, identical shape to
    modules/aws/organizations/delegated_admin's delegated_admins variable. account_ids is wired
    automatically from the accounts created by this same module call's `accounts` input, so entries may
    set account_key to reference an account from var.accounts directly, in addition to a literal
    account_id for existing/external accounts.

    Validation of each entry (exactly one of account_id/account_key, a non-empty services list, and that
    account_key resolves to a real entry) happens inside the delegated_admin submodule itself -- see that
    module's variable description and README for the full interface and examples.
  EOT
  type = map(object({
    account_id  = optional(string)
    account_key = optional(string)
    services    = list(string)
  }))
  default = {}
}

############################################################
# General Variables
############################################################

variable "tags" {
  description = "(Optional) A mapping of tags applied to every Organizational Unit and Account created by this module, merged with each entry's optional per-resource tags. Fans out to both the account and ou submodules, and AWS applies the same tag character rules to OU tags. Tag keys and values must consist only of letters, numbers, spaces, and the characters + - = . _ : / @ (AWS Organizations' allowed tag character set). Tag keys must be non-empty; tag values may be empty."
  type        = map(string)
  default = {
    terraform = "true"
  }

  # See the accounts variable above for why this is validated here rather than only relying on the
  # submodules alone (issue #496). This single pair of blocks covers both the account and ou submodules,
  # since var.tags fans out to both.
  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags : can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]+$", tag_key))
    ])
    error_message = join(" ", concat(
      ["Each tags key must consist only of letters, numbers, spaces, and the characters + - = . _ : / @ (AWS Organizations' allowed tag character set). Offending keys:"],
      [
        for tag_key, tag_value in var.tags : tag_key
        if !can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]+$", tag_key))
      ]
    ))
  }

  validation {
    condition = alltrue([
      for tag_key, tag_value in var.tags : can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]*$", tag_value))
    ])
    error_message = join(" ", concat(
      ["Each tags value must consist only of letters, numbers, spaces, and the characters + - = . _ : / @ (AWS Organizations' allowed tag character set). Offending keys (values omitted to avoid echoing long strings):"],
      [
        for tag_key, tag_value in var.tags : tag_key
        if !can(regex("^[\\p{L}\\p{N}\\p{Z}+\\-=._:/@]*$", tag_value))
      ]
    ))
  }
}
