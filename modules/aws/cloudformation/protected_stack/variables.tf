###########################
# Stack Inputs
###########################
variable "capabilities" {
  description = "IAM and macro capabilities acknowledged for the template."
  type        = list(string)
  default     = null

  validation {
    condition = var.capabilities == null ? true : alltrue([
      for capability in var.capabilities :
      contains(["CAPABILITY_IAM", "CAPABILITY_NAMED_IAM", "CAPABILITY_AUTO_EXPAND"], capability)
    ])
    error_message = "Capabilities must be CAPABILITY_IAM, CAPABILITY_NAMED_IAM, or CAPABILITY_AUTO_EXPAND."
  }
}

variable "disable_rollback" {
  description = "Disable rollback on creation failure. When true, on_failure is omitted."
  type        = bool
  default     = false
  nullable    = false
}

variable "iam_role_arn" {
  description = "Existing CloudFormation service role ARN; null uses the existing stack role or deployment credentials."
  type        = string
  default     = null
}

variable "name" {
  description = "Stable stack name. Changing it requires replacement and is blocked by prevent_destroy."
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z][A-Za-z0-9-]{0,127}$", var.name))
    error_message = "The name must start with a letter and contain at most 128 letters, numbers, or hyphens."
  }
}

variable "notification_arns" {
  description = "Regional operational SNS topic ARNs for stack events, not custom-resource service tokens."
  type        = list(string)
  default     = null

  validation {
    condition = var.notification_arns == null ? true : (
      length(var.notification_arns) <= 5 && alltrue([
        for arn in var.notification_arns :
        can(regex("^arn:[a-z0-9-]+:sns:[a-z0-9-]+:[0-9]{12}:[A-Za-z0-9_-]+$", arn))
      ])
    )
    error_message = "Supply no more than five standard SNS topic ARNs; FIFO topics cannot receive CloudFormation events."
  }
}

variable "on_failure" {
  description = "Creation failure behavior, omitted when disable_rollback is true. Null uses the AWS default."
  type        = string
  default     = "ROLLBACK"

  validation {
    condition     = var.on_failure == null ? true : contains(["DO_NOTHING", "ROLLBACK", "DELETE"], var.on_failure)
    error_message = "on_failure must be null, DO_NOTHING, ROLLBACK, or DELETE."
  }
}

variable "parameters" {
  description = "Template parameter names and values."
  type        = map(string)
  default     = null
}

variable "policy_body" {
  description = "JSON stack update policy; mutually exclusive with policy_url."
  type        = string
  default     = null

  validation {
    condition     = var.policy_body == null ? true : can(jsondecode(var.policy_body))
    error_message = "policy_body must be valid JSON."
  }
}

variable "policy_url" {
  description = "Stack update policy URL; mutually exclusive with policy_body."
  type        = string
  default     = null
}

variable "region" {
  description = "Resource region override; null uses the AWS provider region."
  type        = string
  default     = null
}

variable "tags" {
  description = "Stack tags. The Name tag is always set to the stack name."
  type        = map(string)
  default     = {}
  nullable    = false
}

variable "template_body" {
  description = "JSON or YAML CloudFormation template body; provide exactly one of template_body and template_url."
  type        = string
  default     = null
}

variable "template_url" {
  description = "CloudFormation template URL; provide exactly one of template_body and template_url."
  type        = string
  default     = null
}

variable "timeout_in_minutes" {
  description = "AWS creation timeout in whole minutes; distinct from provider operation timeouts."
  type        = number
  default     = 60
  nullable    = false

  validation {
    condition     = var.timeout_in_minutes > 0 && floor(var.timeout_in_minutes) == var.timeout_in_minutes
    error_message = "timeout_in_minutes must be a positive whole number."
  }
}

variable "timeouts" {
  description = "Provider operation timeouts. Null attributes use the provider's 30-minute defaults."
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  default  = {}
  nullable = false
}
