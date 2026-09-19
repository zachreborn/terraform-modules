variable "customer_managed_iam_policy_name" {
  description = "(Optional) The name of the customer managed IAM policy to attach to a Permission Set. If this is set, the module will utilize a customer_managed_policy_attachment."
  type        = string
  default     = null
}

variable "customer_managed_iam_policy_path" {
  description = "(Optional) The path of the customer managed IAM policy to attach to a Permission Set."
  type        = string
  default     = "/"
}

variable "description" {
  description = "(Optional) The description of the permission set."
  type        = string
  default     = null
}

variable "groups" {
  description = <<-EOT
    (Optional) Group display names to resolve via the aws_identitystore_group data source and
    associate with the permission set. Names supplied here must already exist in AWS Identity Store
    at plan time. Keys present in group_ids are resolved from that map instead and skipped here.
  EOT
  type        = set(string)
  default     = []
}

variable "group_ids" {
  description = <<-EOT
    (Optional) Pre-resolved Identity Store group IDs keyed by the same logical group name used in
    groups / the assignment keys. Use this to bypass the name-based data source lookup entirely --
    e.g. pass a group's id output so a new group and its permission set can be created in one apply.
    Values may be known-only-after-apply. If the same key appears in both groups and group_ids,
    group_ids wins and the data source lookup is skipped for it.
  EOT
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.group_ids : v != null && v != ""])
    error_message = "Each group_ids value must be a non-empty string."
  }
}

variable "group_attribute_path" {
  description = "(Optional) The path of the group attribute in AWS SSO. This value is used to uniquely identify groups in AWS SSO."
  type        = string
  default     = "DisplayName"
}

variable "inline_policy" {
  description = "(Optional) The IAM inline policy to attach to a Permission Set. If this is set, the module will utilize an inline_policy."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "(Optional) List of ARNs of the IAM managed policy to attach to a Permission Set. If this is set, the module will utilize a managed_policy_attachment."
  type        = list(string)
  default     = []
}

variable "name" {
  description = "(Required) The name of the permission set."
  type        = string
}

variable "relay_state" {
  description = "(Optional) The relay state URL used to redirect users within the application during the federation authentication process."
  type        = string
  default     = null
}

variable "session_duration" {
  description = "(Optional) The length of time that the application user sessions are valid in the ISO-8601 standard."
  type        = string
  default     = "PT1H"
}

variable "tags" {
  description = "(Optional) Key-value map of resource tags."
  type        = map(string)
  default     = {}
}

variable "target_accounts" {
  description = <<-EOT
    (Required) Map of AWS accounts to assign the permission set to. The key is a static,
    caller-defined label (e.g. an account name/alias) that must be known at plan time and must not
    contain an underscore ('_'); the value is the AWS account ID, which may be a computed reference
    (e.g. a newly created account's id) that is only known after apply. Keying by a static label --
    instead of the account ID itself -- keeps the underlying aws_ssoadmin_account_assignment for_each
    key plan-time-known even when the account ID is not, which is what allows a brand-new account and
    its permission set assignment to be created together in the same apply. Each account ID value
    must also be unique across labels: the module assigns one aws_ssoadmin_account_assignment per
    group x label pair, so reusing the same account ID under two labels would create two resources
    managing the identical AWS assignment under separate addresses.
  EOT
  type        = map(string)
  # Example:
  # target_accounts = {
  #   organization   = "123456789012"
  #   security       = "123456789013"
  #   logging        = "123456789014"
  #   infrastructure = "123456789015"
  # }

  validation {
    condition     = length(distinct(values(var.target_accounts))) == length(var.target_accounts)
    error_message = "Each value in target_accounts (the AWS account ID) must be unique. Assigning the same account ID under two different labels would create two aws_ssoadmin_account_assignment resources managing the identical AWS assignment under separate addresses, which can conflict on create and inconsistently revoke access if either address is later destroyed."
  }

  # Labels drive the "${group_name}_${label}" assignment key (main.tf). If a label could contain an
  # underscore, two distinct (group, label) pairs could concatenate to the same string -- e.g. group
  # "a" + label "b_c" collides with group "a_b" + label "c" -- which fails at plan time with a
  # confusing "Duplicate object key" error instead of this clear, actionable message. Forbidding
  # underscores in labels alone is sufficient to make the concatenation unambiguous regardless of what
  # characters appear in group_name (which this module does not control -- it comes from AWS Identity
  # Store display names or caller-supplied group_ids/group_keys names).
  validation {
    condition     = alltrue([for k in keys(var.target_accounts) : length(regexall("_", k)) == 0])
    error_message = "target_accounts keys (labels) must not contain an underscore ('_'). The underlying aws_ssoadmin_account_assignment for_each key is derived as \"<group_name>_<label>\"; allowing an underscore in the label makes that concatenation ambiguous (e.g. group \"a\" + label \"b_c\" collides with group \"a_b\" + label \"c\"), which can fail at plan time with a duplicate object key error."
  }
}
