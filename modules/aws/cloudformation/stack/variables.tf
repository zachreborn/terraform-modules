###########################
# Resource Variables
###########################
variable "capabilities" {
  description = "A list of capabilities that AWS CloudFormation can use. Valid values are: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND."
  type        = list(string)
  default     = null
  validation {
    condition     = var.capabilities == null || alltrue([for cap in var.capabilities : contains(["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"], cap)])
    error_message = "capabilities must be null or a list from these options: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND."
  }
}

variable "disable_rollback" {
  description = "Whether to disable rollback on stack creation failures. Conflicts with 'on_failure' parameter."
  type        = bool
  default     = false
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role to use for the CloudFormation stack. If this is not set, CloudFormation uses the role that was previously associated with the stack. If no role has been set, CloudFormation uses a temporary session generated from the user credentials."
  type        = string
  default     = null
}

variable "name" {
  description = "The name of the stack. Must be unique in the region in which you are creating the stack."
  type        = string
}

variable "notification_arns" {
  description = "A list of SNS topic ARNs to which stack-related events are published."
  type        = list(string)
  default     = null
}

variable "on_failure" {
  description = "Action to be taken if the stack fails to create. This must be one of: DO_NOTHING, ROLLBACK, or DELETE."
  type        = string
  default     = "ROLLBACK"
  validation {
    condition     = can(regex("^(DO_NOTHING|ROLLBACK|DELETE)$", var.on_failure))
    error_message = "on_failure must be one of: DO_NOTHING, ROLLBACK, or DELETE."
  }
}

variable "parameters" {
  description = "A map of parameters to pass to the CloudFormation template."
  type        = map(string)
  default     = null
}

variable "policy_body" {
  description = "Structure containing the stack policy body. Conflicts with 'policy_url' parameter."
  type        = string
  default     = null
}

variable "policy_url" {
  description = "URL of the stack policy. Conflicts with 'policy_body' parameter."
  type        = string
  default     = null
}

variable "template_body" {
  description = "Structure containing the template body with a minimum length of 1 byte and a maximum length of 51,200 bytes. Conflicts with 'template_url' parameter."
  type        = string
  default     = null
}

variable "template_url" {
  description = "URL of the CloudFormation template. Conflicts with 'template_body' parameter."
  type        = string
  default     = null
}

variable "timeout_in_minutes" {
  description = "The amount of time in minutes that CloudFormation waits for a stack to be created or updated before timing out."
  type        = number
  default     = 60
  validation {
    condition     = var.timeout_in_minutes > 0
    error_message = "timeout_in_minutes must be greater than 0."
  }
}

###########################
# General Variables
###########################

variable "tags" {
  description = "A map of tags to assign to the stack."
  type        = map(string)
  default     = {}
}
