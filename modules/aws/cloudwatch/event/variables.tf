###########################
# CloudWatch EventBridge Rule Variables
###########################
variable "description" {
  description = "Description of the cloudwatch event."
  type        = string
  default     = null
}

variable "event_bus_name" {
  description = "The name or ARN of the event bus to associate with this rule. If not provided, the default event bus will be used."
  type        = string
  default     = null
}

variable "event_pattern" {
  description = "JSON string for the event pattern. Either event_pattern or schedule_expression must be provided, but not both."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Name prefix for the cloudwatch event rule. Must be 38 characters or less. Mutually exclusive with name."
  type        = string
  default     = null
  validation {
    condition     = var.name_prefix == null || length(var.name_prefix) <= 38
    error_message = "Name prefix must be 38 characters or less."
  }
}

variable "role_arn" {
  description = "The ARN of the IAM role to associate with this rule."
  type        = string
  default     = null
}

variable "schedule_expression" {
  description = "The scheduling expression for the rule, e.g. cron(0 20 * * ? *) or rate(5 minutes). Either schedule_expression or event_pattern must be provided, but not both."
  type        = string
  default     = null
}

variable "state" {
  description = "The state of the rule. Valid values are ENABLED, DISABLED, or ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS."
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED", "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"], var.state)
    error_message = "State must be one of ENABLED, DISABLED, or ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS."
  }
}

###########################
# CloudWatch EventBridge Target Variables
###########################
variable "event_target_arn" {
  description = "ARN of the target resource to invoke when the rule is triggered."
  type        = string
}

variable "input_transformer" {
  description = "Input transformer to extract values from the event and pass them to the target in a custom format. Only one input_transformer is supported per event target."
  type = object({
    input_paths    = map(string)
    input_template = string
  })
  default = null
}

variable "target_id" {
  description = "The unique target assignment ID."
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default = {
    "terraform" = "true"
  }
}
