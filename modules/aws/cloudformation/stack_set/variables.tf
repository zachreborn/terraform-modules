###########################
# Stack Set Variables
###########################
variable "administration_role_arn" {
  description = "The ARN of the IAM role that CloudFormation assumes to perform stack operations. Must be set when using the SELF_MANAGED permission model"
  type        = string
  default     = null
}

variable "call_as" {
  description = "Specifies whether you are acting as an account administrator in the management account or as a delegated administrator in a member account. Valid values are: SELF, DELEGATED_ADMIN"
  type        = string
  default     = "SELF"
  validation {
    condition     = can(regex("^(SELF|DELEGATED_ADMIN)$", var.call_as))
    error_message = "call_as must be one of: SELF, DELEGATED_ADMIN."
  }
}

variable "capabilities" {
  description = "A list of capabilities that AWS CloudFormation can use. Valid values are: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND."
  type        = list(string)
  default     = null
  validation {
    condition     = var.capabilities == null || alltrue([for cap in var.capabilities : contains(["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"], cap)])
    error_message = "capabilities must be null or a list from these options: CAPABILITY_IAM, CAPABILITY_NAMED_IAM, CAPABILITY_AUTO_EXPAND."
  }
}

variable "description" {
  description = "A description of the stack set."
  type        = string
  default     = null
}

variable "enable_auto_deployment" {
  description = "Whether to enable automatic deployment of stack set updates to AWS Organizations accounts that are added to the target organization or organizational unit (OU). Only available when using the SERVICE_MANAGED permission model."
  type        = bool
  default     = true
}

variable "enable_managed_execution" {
  description = "Whether to enable managed execution for stack set operations. When true, Stack Sets will perform non-conflicting operations concurrently and queue conflicting operations."
  type        = bool
  default     = false
}

variable "execution_role_name" {
  description = "The name of the IAM role to use for the CloudFormation stack. When using the SELF_MANAGED permission mode, this defaults to AWSCloudFormationStackSetExecutionRole. When using the SERVICE_MANAGED permission model, this should remain null."
  type        = string
  default     = null
}

variable "failure_tolerance_count" {
  description = "The number of failed accounts per region that CloudFormation tolerates before stopping the stack set operation in that region."
  type        = number
  default     = 0
}

variable "failure_tolerance_percentage" {
  description = "The percentage of failed accounts per region that CloudFormation tolerates before stopping the stack set operation in that region."
  type        = number
  default     = null
}

variable "max_concurrent_count" {
  description = "The maximum number of accounts in which to create or update the stack set instance at the same time."
  type        = number
  default     = 1
}

variable "max_concurrent_percentage" {
  description = "The maximum percentage of accounts in which to create or update the stack set instance at the same time."
  type        = number
  default     = null
}

variable "name" {
  description = "The name of the stack set. Must be unique in the region in which you are creating the stack set."
  type        = string
}

variable "parameters" {
  description = "A map of parameters to pass to the CloudFormation template."
  type        = map(string)
  default     = null
}

variable "permission_model" {
  description = "The permissions model to use to create the stack set. Valid values are: SERVICE_MANAGED, SELF_MANAGED"
  type        = string
  default     = "SERVICE_MANAGED"
  validation {
    condition     = can(regex("^(SERVICE_MANAGED|SELF_MANAGED)$", var.permission_model))
    error_message = "permission_model must be one of: SERVICE_MANAGED, SELF_MANAGED."
  }
}

variable "region_concurrency_type" {
  description = "The concurrency type of the stack set operation. Valid values are: SEQUENTIAL, PARALLEL"
  type        = string
  default     = "SEQUENTIAL"
  validation {
    condition     = can(regex("^(SEQUENTIAL|PARALLEL)$", var.region_concurrency_type))
    error_message = "region_concurrency_type must be one of: SEQUENTIAL, PARALLEL."
  }
}

variable "region_order" {
  description = "The order of the regions in which to create or update stack set instances."
  type        = list(string)
  default     = null
}

variable "retain_stacks_on_account_removal" {
  description = "Whether to retain stack instances in accounts that are removed from the stack set."
  type        = bool
  default     = false
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
  validation {
    condition     = var.template_url == null || can(regex("^(https://).+", var.template_url))
    error_message = "template_url must be null or a valid https URL."
  }
}

###########################
# Stack Set Instance Variables
###########################
variable "accounts" {
  description = "A list of AWS account IDs to deploy the stack set instances to."
  type        = list(string)
  default     = null
}

variable "account_filter_type" {
  description = "Limit deployment targets to a specific type of account. Valid values are: DIFFERENCE, INTERSECTION, NONE, UNION."
  type        = string
  default     = null
}

variable "accounts_url" {
  description = "S3 URL of a file which contains a list of accounts to deploy the stack set instances to."
  type        = string
  default     = null
}

variable "organizational_unit_ids" {
  description = "A list of organization unit IDs to deploy the stack set instances to."
  type        = list(string)
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "A map of tags to assign to the stack."
  type        = map(string)
  default     = {}
}
