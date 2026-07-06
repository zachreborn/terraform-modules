############################################################
# AWS Organization Account
############################################################

variable "accounts" {
  description = <<-EOT
    (Required) Map of AWS Organization member accounts to create, keyed by a caller-chosen logical name
    (e.g. "company_name").
    Each entry must set exactly one of:
      - parent_id:  A literal parent Root or Organizational Unit ID.
      - parent_key: A key into var.organizational_unit_ids (e.g. the `ids` output of
                    modules/aws/organizations/ou) identifying the OU this account should be attached to.
    Bare/null entries (e.g. an empty `foo:` in YAML) are not supported here, unlike
    modules/aws/organizations/ou — there is no reasonable default for email, so every entry must at minimum
    set email.
    Fields:
      - name:                       (Optional) A friendly name for the member account. Defaults to the
                                     entry's map key when unset.
      - email:                      (Required) The email address of the owner to assign to the new member
                                     account. This email address must not already be associated with
                                     another AWS account.
      - parent_id:                  (Optional) Literal parent Root or OU ID. Conflicts with parent_key.
      - parent_key:                 (Optional) Key into var.organizational_unit_ids. Conflicts with parent_id.
      - iam_user_access_to_billing: (Optional) ALLOW or DENY. Defaults to ALLOW.
      - role_name:                  (Optional) Name of the IAM role Organizations preconfigures in the new
                                     account. Defaults to OrganizationAccountAccessRole.
      - close_on_deletion:          (Optional) If true, a deletion event will close the account. Defaults to false.
      - tags:                       (Optional) Additional tags for this account, merged with var.tags.
  EOT
  type = map(object({
    name                       = optional(string)
    email                      = string
    parent_id                  = optional(string)
    parent_key                 = optional(string)
    iam_user_access_to_billing = optional(string, "ALLOW")
    role_name                  = optional(string, "OrganizationAccountAccessRole")
    close_on_deletion          = optional(bool, false)
    tags                       = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.accounts : v != null
    ])
    error_message = "Each accounts entry must be an object that sets at least email; bare/null entries are not supported since there is no reasonable default account email."
  }

  validation {
    condition = alltrue([
      for k, v in var.accounts : v != null ? (v.parent_id != null) != (v.parent_key != null) : true
    ])
    error_message = "Each accounts entry must set exactly one of parent_id or parent_key."
  }
}

variable "organizational_unit_ids" {
  description = "(Optional) Map of Organizational Unit IDs keyed by logical name, e.g. the `ids` output of modules/aws/organizations/ou. Referenced by each accounts entry's parent_key."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "(Optional) Key-value map of resource tags applied to every account, merged with each entry's optional per-account tags. If configured with a provider default_tags configuration block present, tags with matching keys will overwrite those defined at the provider-level."
  type        = map(any)
  default     = {}
}
