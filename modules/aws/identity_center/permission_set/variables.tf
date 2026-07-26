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
  description = "(Required) The list of AWS account IDs to assign the permission set to."
  type        = set(string)
  # Example:
  # target_accounts = [
  #   "123456789012",
  #   "123456789013",
  #   "123456789014",
  #   "123456789015"
  # ]
}
