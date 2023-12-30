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
  description = "(Optional) The group names to lookup and associate with the permission set."
  type        = list(string)
  default     = []
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

variable "managed_policy_arn" {
  description = "(Optional) The ARN of the IAM managed policy to attach to a Permission Set. If this is set, the module will utilize a managed_policy_attachment."
  type        = string
  default     = null
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
