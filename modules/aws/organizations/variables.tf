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
    aws_service_access_principals      = optional(list(string))
    enabled_policy_types               = optional(list(string))
    feature_set                        = optional(string)
    enabled_features                   = optional(list(string))
    enable_identity_center_scp         = optional(bool)
    identity_center_scp_name           = optional(string)
    identity_center_scp_description    = optional(string)
    attach_identity_center_scp         = optional(bool)
    identity_center_scp_target_ids     = optional(list(string))
    enable_region_scp                  = optional(bool)
    allowed_regions                    = optional(list(string))
    region_scp_name                    = optional(string)
    region_scp_description             = optional(string)
    attach_region_scp                  = optional(bool)
    region_scp_target_ids              = optional(list(string))
    region_scp_exempted_principal_arns = optional(list(string))
    region_scp_exempted_actions        = optional(list(string))
    enable_organization_backup         = optional(bool)
    tags                               = optional(map(string))
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
}

############################################################
# General Variables
############################################################

variable "tags" {
  description = "(Optional) A mapping of tags applied to every Organizational Unit and Account created by this module, merged with each entry's optional per-resource tags."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
