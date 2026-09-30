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

variable "target_accounts" {
  description = "(Required) Map of static, caller-defined label to AWS account ID. The label keys the underlying for_each (and must be known at plan time); the account ID may be known only after apply. Labels may contain any characters."
  type        = map(string)
}
