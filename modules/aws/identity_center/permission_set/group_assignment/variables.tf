variable "group_id" {
  description = "(Required) The Identity Store group ID (principal ID) the permission set is assigned to. May be known only after apply."
  type        = string
}

variable "instance_arn" {
  description = "(Required) The ARN of the IAM Identity Center instance the permission set belongs to."
  type        = string
}

variable "permission_set_arn" {
  description = "(Required) The ARN of the permission set to assign."
  type        = string
}

variable "region" {
  description = "(Optional) Region where the account assignments are managed. Defaults to the Region set in the provider configuration. It must be the Region of the IAM Identity Center instance and permission set being assigned."
  type        = string
  default     = null
}

variable "target_accounts" {
  description = "(Required) Map of static, caller-defined label to AWS account ID. The label keys the underlying for_each (and must be known at plan time); the account ID may be known only after apply. Labels may contain any characters. Each account ID must be unique across labels."
  type        = map(string)

  validation {
    condition     = length(distinct(values(var.target_accounts))) == length(var.target_accounts)
    error_message = "Each value in target_accounts (the AWS account ID) must be unique. Assigning the same account ID under two different labels would create two aws_ssoadmin_account_assignment resources managing the identical AWS assignment under separate addresses, which can conflict on create and inconsistently revoke access if either address is later destroyed."
  }
}

variable "timeouts" {
  description = "(Optional) Operation timeouts applied to every aws_ssoadmin_account_assignment, as a map with the optional keys 'create' and 'delete' (for example { create = \"10m\", delete = \"10m\" }). Unset keys use the provider defaults (5m each)."
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k in keys(var.timeouts) : contains(["create", "delete"], k)])
    error_message = "timeouts may only contain the keys 'create' and 'delete'."
  }
}
