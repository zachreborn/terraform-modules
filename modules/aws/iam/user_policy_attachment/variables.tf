variable "policy_arn" {
  type        = string
  default     = null
  description = "(Optional) - The ARN of the policy you want to apply. Mutually exclusive with 'policy_name'; exactly one of the two must be set."
}

variable "policy_name" {
  type        = string
  default     = null
  description = "(Optional) - The name of an AWS managed or customer-managed policy (as shown in IAM) to look up via the aws_iam_policy data source and attach. Mutually exclusive with 'policy_arn'; exactly one of the two must be set."
}

variable "user" {
  type        = string
  description = "(Required) - The user the policy should be applied to"
}
