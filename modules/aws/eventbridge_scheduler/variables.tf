###########################
# Schedule Variables
###########################

variable "name" {
  description = "(Optional) Name of the schedule. Forces replacement. Mutually exclusive with name_prefix; exactly one of name or name_prefix must be set."
  type        = string
  default     = null
  validation {
    condition     = var.name == null || can(regex("^[0-9a-zA-Z-_.]{1,64}$", var.name))
    error_message = "name must be 1-64 characters and contain only alphanumeric characters, hyphens, underscores, and periods."
  }
}

variable "name_prefix" {
  description = "(Optional) Creates a unique schedule name beginning with this prefix. Forces replacement. Mutually exclusive with name; exactly one of name or name_prefix must be set."
  type        = string
  default     = null
  validation {
    condition     = var.name_prefix == null || can(regex("^[0-9a-zA-Z-_.]{1,64}$", var.name_prefix))
    error_message = "name_prefix must be 1-64 characters and contain only alphanumeric characters, hyphens, underscores, and periods."
  }
}

variable "group_name" {
  description = "(Optional) Name of the schedule group to associate this schedule with. AWS uses the 'default' group when omitted. Forces replacement."
  type        = string
  default     = null
  validation {
    condition     = var.group_name == null || can(regex("^[0-9a-zA-Z-_.]{1,64}$", var.group_name))
    error_message = "group_name must be 1-64 characters and contain only alphanumeric characters, hyphens, underscores, and periods."
  }
}

variable "description" {
  description = "(Optional) Brief description of the schedule."
  type        = string
  default     = null
  validation {
    condition     = var.description == null || length(var.description) <= 512
    error_message = "description must be 512 characters or less."
  }
}

variable "schedule_expression" {
  description = "(Required) Defines when the schedule runs: at(...), rate(...), or cron(...). See https://docs.aws.amazon.com/scheduler/latest/UserGuide/schedule-types.html."
  type        = string
  validation {
    condition     = can(regex("^(at|rate|cron)\\(.+\\)$", var.schedule_expression))
    error_message = "schedule_expression must be an at(...), rate(...), or cron(...) expression."
  }
}

variable "schedule_expression_timezone" {
  description = "(Optional) IANA timezone in which schedule_expression is evaluated."
  type        = string
  default     = "UTC"
  validation {
    condition     = length(var.schedule_expression_timezone) > 0
    error_message = "schedule_expression_timezone must not be empty."
  }
}

variable "start_date" {
  description = "(Optional) UTC RFC3339 instant after which the schedule may begin invoking its target, e.g. 2030-01-01T01:00:00Z. Ignored for one-time schedules."
  type        = string
  default     = null
  validation {
    condition     = var.start_date == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", var.start_date))
    error_message = "start_date must be a UTC RFC3339 timestamp, e.g. 2030-01-01T01:00:00Z."
  }
}

variable "end_date" {
  description = "(Optional) UTC RFC3339 instant before which the schedule can invoke its target, e.g. 2030-01-01T01:00:00Z. Ignored for one-time schedules. Must be strictly later than start_date when both are set."
  type        = string
  default     = null
  validation {
    condition     = var.end_date == null || can(regex("^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$", var.end_date))
    error_message = "end_date must be a UTC RFC3339 timestamp, e.g. 2030-01-01T01:00:00Z."
  }
}

variable "state" {
  description = "(Optional) Whether the schedule is enabled or disabled."
  type        = string
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.state)
    error_message = "state must be one of ENABLED or DISABLED."
  }
}

variable "action_after_completion" {
  description = "(Optional) Action applied to the schedule after completing invocation of its target."
  type        = string
  default     = null
  validation {
    condition     = var.action_after_completion == null || contains(["NONE", "DELETE"], var.action_after_completion)
    error_message = "action_after_completion must be one of NONE or DELETE."
  }
}

variable "kms_key_arn" {
  description = "(Optional) ARN of the customer managed KMS key EventBridge Scheduler uses to encrypt and decrypt the schedule's data. The caller must provision this key; this module does not call modules/aws/kms."
  type        = string
  default     = null
  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:", var.kms_key_arn))
    error_message = "kms_key_arn must be a valid ARN."
  }
}

variable "region" {
  description = "(Optional) Region where the schedule is managed. Defaults to the Region set in the provider configuration."
  type        = string
  default     = null
}

variable "flexible_time_window" {
  description = "(Optional) Configures the time window during which EventBridge Scheduler may invoke the schedule."
  type = object({
    mode                      = optional(string, "OFF")
    maximum_window_in_minutes = optional(number)
  })
  default = { mode = "OFF" }
  validation {
    condition     = contains(["OFF", "FLEXIBLE"], var.flexible_time_window.mode)
    error_message = "flexible_time_window.mode must be one of OFF or FLEXIBLE."
  }
  validation {
    condition = var.flexible_time_window.mode != "FLEXIBLE" || (
      var.flexible_time_window.maximum_window_in_minutes != null &&
      var.flexible_time_window.maximum_window_in_minutes >= 1 &&
      var.flexible_time_window.maximum_window_in_minutes <= 1440
    )
    error_message = "flexible_time_window.maximum_window_in_minutes is required and must be between 1 and 1440 when mode is FLEXIBLE."
  }
  validation {
    condition     = var.flexible_time_window.mode != "OFF" || var.flexible_time_window.maximum_window_in_minutes == null
    error_message = "flexible_time_window.maximum_window_in_minutes must not be set when mode is OFF."
  }
}

###########################
# Target Variables
###########################

variable "target_arn" {
  description = "(Required) ARN of the target to invoke, or a universal-target service ARN (arn:<partition>:scheduler:::aws-sdk:<service>:<action>)."
  type        = string
  validation {
    condition     = can(regex("^arn:", var.target_arn))
    error_message = "target_arn must be a valid ARN."
  }
}

variable "target_input" {
  description = "(Optional) Text, or well-formed JSON, passed to the target on every invocation, e.g. jsonencode({ apply = false })."
  type        = string
  default     = null
}

variable "target_role_arn" {
  description = "(Optional) ARN of an existing IAM role for EventBridge Scheduler to assume when invoking the target. When omitted, this module creates a least-privilege invoke role via modules/aws/iam/role and modules/aws/iam/policy."
  type        = string
  default     = null
  validation {
    condition     = var.target_role_arn == null || can(regex("^arn:", var.target_role_arn))
    error_message = "target_role_arn must be a valid ARN."
  }
}

variable "target_dead_letter_arn" {
  description = "(Optional) ARN of the SQS queue EventBridge Scheduler uses as a dead-letter queue for failed target invocations. The caller must provision this queue; this module does not call modules/aws/sqs_queue."
  type        = string
  default     = null
  validation {
    condition     = var.target_dead_letter_arn == null || can(regex("^arn:", var.target_dead_letter_arn))
    error_message = "target_dead_letter_arn must be a valid ARN."
  }
}

variable "target_retry_policy" {
  description = "(Optional) Retry policy settings for the target."
  type = object({
    maximum_event_age_in_seconds = optional(number)
    maximum_retry_attempts       = optional(number)
  })
  default = null
  validation {
    condition = var.target_retry_policy == null || var.target_retry_policy.maximum_event_age_in_seconds == null || (
      var.target_retry_policy.maximum_event_age_in_seconds >= 60 &&
      var.target_retry_policy.maximum_event_age_in_seconds <= 86400
    )
    error_message = "target_retry_policy.maximum_event_age_in_seconds must be between 60 and 86400."
  }
  validation {
    condition = var.target_retry_policy == null || var.target_retry_policy.maximum_retry_attempts == null || (
      var.target_retry_policy.maximum_retry_attempts >= 0 &&
      var.target_retry_policy.maximum_retry_attempts <= 185
    )
    error_message = "target_retry_policy.maximum_retry_attempts must be between 0 and 185."
  }
}

variable "target_ecs_parameters" {
  description = "(Optional) Templated target parameters for the Amazon ECS RunTask API operation. Set target_role_policy_actions and target_role_policy_resources explicitly when this is used, since the ecs:RunTask invoke action cannot be derived automatically."
  type = object({
    task_definition_arn = string
    capacity_provider_strategy = optional(list(object({
      capacity_provider = string
      base              = optional(number)
      weight            = optional(number)
    })), [])
    enable_ecs_managed_tags = optional(bool)
    enable_execute_command  = optional(bool)
    group                   = optional(string)
    launch_type             = optional(string)
    network_configuration = optional(object({
      assign_public_ip = optional(bool)
      security_groups  = optional(set(string))
      subnets          = optional(set(string))
    }))
    placement_constraints = optional(list(object({
      type       = string
      expression = optional(string)
    })), [])
    placement_strategy = optional(list(object({
      type  = string
      field = optional(string)
    })), [])
    platform_version = optional(string)
    propagate_tags   = optional(string)
    reference_id     = optional(string)
    tags             = optional(map(string))
    task_count       = optional(number)
  })
  default = null
  validation {
    condition     = var.target_ecs_parameters == null || var.target_ecs_parameters.launch_type == null || contains(["EC2", "FARGATE", "EXTERNAL"], var.target_ecs_parameters.launch_type)
    error_message = "target_ecs_parameters.launch_type must be one of EC2, FARGATE, or EXTERNAL."
  }
  validation {
    condition     = var.target_ecs_parameters == null || var.target_ecs_parameters.task_count == null || (var.target_ecs_parameters.task_count >= 1 && var.target_ecs_parameters.task_count <= 10)
    error_message = "target_ecs_parameters.task_count must be between 1 and 10."
  }
  validation {
    condition     = var.target_ecs_parameters == null || length(var.target_ecs_parameters.capacity_provider_strategy) <= 6
    error_message = "target_ecs_parameters.capacity_provider_strategy supports at most 6 entries."
  }
  validation {
    condition     = var.target_ecs_parameters == null || length(var.target_ecs_parameters.placement_constraints) <= 10
    error_message = "target_ecs_parameters.placement_constraints supports at most 10 entries."
  }
  validation {
    condition     = var.target_ecs_parameters == null || length(var.target_ecs_parameters.placement_strategy) <= 5
    error_message = "target_ecs_parameters.placement_strategy supports at most 5 entries."
  }
}

variable "target_eventbridge_parameters" {
  description = "(Optional) Templated target parameters for the EventBridge PutEvents API operation."
  type = object({
    detail_type = string
    source      = string
  })
  default = null
  validation {
    condition     = var.target_eventbridge_parameters == null || length(var.target_eventbridge_parameters.detail_type) <= 128
    error_message = "target_eventbridge_parameters.detail_type must be 128 characters or less."
  }
}

variable "target_kinesis_parameters" {
  description = "(Optional) Templated target parameters for the Amazon Kinesis PutRecord API operation."
  type = object({
    partition_key = string
  })
  default = null
  validation {
    condition     = var.target_kinesis_parameters == null || (length(var.target_kinesis_parameters.partition_key) >= 1 && length(var.target_kinesis_parameters.partition_key) <= 256)
    error_message = "target_kinesis_parameters.partition_key must be between 1 and 256 characters."
  }
}

variable "target_sagemaker_pipeline_parameters" {
  description = "(Optional) Templated target parameters for the Amazon SageMaker AI StartPipelineExecution API operation."
  type = object({
    pipeline_parameter = optional(list(object({
      name  = string
      value = string
    })), [])
  })
  default = null
  validation {
    condition     = var.target_sagemaker_pipeline_parameters == null || length(var.target_sagemaker_pipeline_parameters.pipeline_parameter) <= 200
    error_message = "target_sagemaker_pipeline_parameters.pipeline_parameter supports at most 200 entries."
  }
}

variable "target_sqs_parameters" {
  description = "(Optional) Templated target parameters for the Amazon SQS SendMessage API operation."
  type = object({
    message_group_id = optional(string)
  })
  default = null
}

###########################
# Created Invoke Role Variables
###########################
# All of these are ignored when target_role_arn is supplied.

variable "target_role_name" {
  description = "(Optional) Name of the invoke role and policy this module creates when target_role_arn is omitted. When null, a name_prefix derived from the schedule name is used instead."
  type        = string
  default     = null
}

variable "target_role_path" {
  description = "(Optional) Path for the created invoke role and policy."
  type        = string
  default     = "/"
}

variable "target_role_permissions_boundary" {
  description = "(Optional) ARN of the permissions boundary policy for the created invoke role."
  type        = string
  default     = null
}

variable "target_role_max_session_duration" {
  description = "(Optional) Maximum session duration, in seconds, for the created invoke role."
  type        = number
  default     = 3600
  validation {
    condition     = var.target_role_max_session_duration >= 3600 && var.target_role_max_session_duration <= 43200
    error_message = "target_role_max_session_duration must be between 3600 and 43200 seconds (1 to 12 hours)."
  }
}

variable "target_role_policy_actions" {
  description = "(Optional) IAM actions the created invoke policy allows. Overrides the action this module would otherwise derive from target_arn's service namespace. Required when the target service cannot be derived (e.g. ECS, universal targets)."
  type        = list(string)
  default     = null
  validation {
    condition     = var.target_role_policy_actions == null || length(var.target_role_policy_actions) > 0
    error_message = "target_role_policy_actions must not be empty when set."
  }
}

variable "target_role_policy_resources" {
  description = "(Optional) Resources the created invoke policy allows target_role_policy_actions against. Defaults to [target_arn] when unset."
  type        = list(string)
  default     = null
  validation {
    condition     = var.target_role_policy_resources == null || (length(var.target_role_policy_resources) > 0 && alltrue([for r in var.target_role_policy_resources : can(regex("^arn:", r))]))
    error_message = "target_role_policy_resources must not be empty when set, and every element must be a valid ARN."
  }
}

variable "target_role_additional_policy_arns" {
  description = "(Optional) Additional managed or customer-managed policy ARNs to attach to the created invoke role alongside the generated least-privilege policy (e.g. kms:GenerateDataKey for an encrypted SQS target)."
  type        = list(string)
  default     = []
  validation {
    condition     = alltrue([for a in var.target_role_additional_policy_arns : can(regex("^arn:", a))])
    error_message = "Every element of target_role_additional_policy_arns must be a valid ARN."
  }
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags applied to the composed IAM role and policy. aws_scheduler_schedule has no tags argument (EventBridge Scheduler supports tags only on schedule groups, not individual schedules), so these tags never reach the schedule resource itself."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
