variable "description" {
  type        = string
  description = "(Optional) Description of what your Lambda Function does. When omitted (null), the provider does not set a description on the function."
  default     = null
}

variable "filename" {
  type        = string
  description = "(Optional) The path to the function's deployment package within the local filesystem. If defined, The s3_-prefixed options cannot be used. When omitted (null), a function created without a local package source requires an alternative source (e.g. S3 or a container image) configured outside this module today."
  default     = null
}

variable "source_code_hash" {
  type        = string
  description = "(Optional) Used to trigger updates. Must be set to a base64-encoded SHA256 hash of the package file specified with either filename or s3_key"
  default     = null
}

variable "function_name" {
  type        = string
  description = "(Required) A unique name for your Lambda Function."
}

variable "role" {
  type        = string
  description = "(Required) IAM role attached to the Lambda Function. This governs both who or what can invoke your Lambda Function, as well as what resources our Lambda Function has access to. See Lambda Permission Model for more details."
}

variable "handler" {
  type        = string
  description = "(Required) The function entrypoint in your code."
  default     = "main.handler"
}

variable "memory_size" {
  type        = string
  description = "(Optional) Amount of memory in MB your Lambda Function can use at runtime. Defaults to 128. See Limits"
  default     = 128
}

variable "runtime" {
  type        = string
  description = "(Required) See Runtimes for valid values."
  default     = "python3.6"
}

variable "timeout" {
  type        = number
  description = "(Optional) The amount of time your Lambda Function has to run in seconds. Defaults to 180. See Limits"
  default     = 180
}

variable "variables" {
  type        = map(string)
  description = "(Optional) A map that defines environment variables for the Lambda function."
  default = {
    lambda = "true"
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the Lambda function. A `Name` tag is merged automatically from `function_name`; a caller-supplied `Name` wins."
  default     = {}
}

variable "vpc_config" {
  type = object({
    subnet_ids                  = list(string)
    security_group_ids          = list(string)
    ipv6_allowed_for_dual_stack = optional(bool)
  })
  description = "(Optional) VPC configuration attaching the function to a VPC. When omitted, the function runs outside any VPC. `ipv6_allowed_for_dual_stack` left unset defers to the provider's own default."
  default     = null

  validation {
    condition     = var.vpc_config == null ? true : length(var.vpc_config.subnet_ids) > 0
    error_message = "vpc_config.subnet_ids must contain at least one entry when vpc_config is set."
  }

  validation {
    condition     = var.vpc_config == null ? true : length(var.vpc_config.security_group_ids) > 0
    error_message = "vpc_config.security_group_ids must contain at least one entry when vpc_config is set."
  }
}

variable "reserved_concurrent_executions" {
  type        = number
  description = "(Optional) Amount of reserved concurrent executions for this function. `0` disables the function (throttles all invocations); omit (or `null`) to leave the function unreserved, which is the provider's own default."
  default     = null

  validation {
    condition     = var.reserved_concurrent_executions == null ? true : var.reserved_concurrent_executions >= -1
    error_message = "reserved_concurrent_executions must be null or >= -1 (-1 is AWS's own \"unreserved\" sentinel)."
  }
}

variable "dead_letter_config" {
  type = object({
    target_arn = string
  })
  description = "(Optional) Dead-letter queue configuration. `target_arn` must be an SQS queue or SNS topic ARN, and the function's execution role must be granted `sqs:SendMessage` / `sns:Publish` on it (not managed by this module)."
  default     = null

  validation {
    condition     = var.dead_letter_config == null ? true : can(regex("^arn:[a-z0-9-]+:(sqs|sns):", var.dead_letter_config.target_arn))
    error_message = "dead_letter_config.target_arn must be an SQS or SNS ARN, e.g. arn:aws:sqs:... or arn:aws:sns:...."
  }
}

variable "tracing_config" {
  type = object({
    mode = string
  })
  description = "(Optional) AWS X-Ray tracing mode."
  default     = null

  validation {
    condition     = var.tracing_config == null ? true : contains(["Active", "PassThrough"], var.tracing_config.mode)
    error_message = "tracing_config.mode must be exactly \"Active\" or \"PassThrough\" (case-sensitive)."
  }
}

/*variable "statement_id" {
    description = "A unique statement identifier"
}

variable "action" {
    description = "The AWS lambda action you want to allow"
    default     = "lambda:InvokeFunction"
}

variable "principal" {
    description = "The principal which is receiving this permission"
    default     = "events.amazonaws.com"
}

variable "source_arn" {
    description = "arn of the resource to allow permission to run the lambda function"
}
*/
