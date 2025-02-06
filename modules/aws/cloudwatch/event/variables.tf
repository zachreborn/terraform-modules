###########################
# CloudWatch EventBridge Rule Variables
###########################
variable "description" {
  description = "Description of the cloudwatch event"
}

variable "event_bus_name" {
  description = "The ARN of the event bus to associate with this event. If this is not provided, the default event bus will be used."
  default     = null
}

variable "event_pattern" {
  description = "JSON for the event pattern. Either event_pattern or schedule_expression must be provided."
}

variable "name_prefix" {
  description = "Name prefix for the cloudwatch event. Must be 38 characters or less."
  validation {
    condition     = length(var.name_prefix) <= 38
    error_message = "Name prefix must be 38 characters or less."
  }
}

variable "role_arn" {
  description = "The ARN of the IAM role to use for this event."
  default     = null
}

variable "schedule_expression" {
  description = "cron expression of time or rate expression of time"
}

variable "state" {
  description = "Whether the rule should be enabled or disabled"
  default     = "ENABLED"
}

###########################
# CloudWatch EventBridge Target Variables
###########################
variable "event_target_arn" {
  description = "ARN of the target to invoke with this event."
}

variable "input_transformer" {
  description = "Input transformer for the event target."
  type = list(object({
    input_paths    = map(string)
    input_template = string
  }))
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
