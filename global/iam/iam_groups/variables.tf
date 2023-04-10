variable "mfa_required_policy_name" {
  type        = string
  description = "(Optional) Name of MFA IAM the policy"
  default     = "mfa_required_policy"
}

variable "system_admins_description" {
  type        = string
  description = "(Optional, Forces new resource) Description of the IAM policy."
  default     = "System Admins Policy which allows for EC2 management, RDS management, snapshot management, and systems manager to name a few."
}

variable "system_admins_name" {
  type        = string
  description = "(Optional, Forces new resource) The name of the policy. If omitted, Terraform will assign a random, unique name."
  default     = "system_admins_policy"
}

variable "system_admins_path" {
  type        = string
  description = "(Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information."
  default     = "/"
}

variable "powerusers_group_name" {
  type        = string
  description = "IAM group using the powerusers policy"
  default     = "power_users"
}

variable "billing_group_name" {
  type        = string
  description = "IAM group using the billing policy"
  default     = "billing_users"
}

variable "readonly_group_name" {
  type        = string
  description = "IAM group using the readonly policy"
  default     = "readonly_users"
}

variable "powerusers_policy_arn" {
  type        = string
  description = "IAM powerusers group arn"
  default     = "arn:aws:iam::aws:policy/PowerUserAccess"
}

variable "billing_policy_arn" {
  type        = string
  description = "IAM powerusers group arn"
  default     = "arn:aws:iam::aws:policy/job-function/Billing"
}

variable "readonly_policy_arn" {
  type        = string
  description = "IAM powerusers group arn"
  default     = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

variable "system_admins_group_name" {
  type        = string
  description = "IAM group for System Admins which allows access to EC2, RDS, S3, VPC, and Systems Manager"
  default     = "system_admins"
}

variable "system_admins_policy_arn" {
  type        = string
  description = "IAM System Admins group arn"
  default     = "arn:aws:iam::aws:policy/PowerUserAccess"
}
