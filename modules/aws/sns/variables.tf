###########################
# Resource Variables
###########################

###########################
# SNS Topic
###########################

variable "application_failure_feedback_role_arn" {
  description = "IAM role ARN for delivery status failure feedback for application endpoints."
  type        = string
  default     = null
}

variable "application_success_feedback_role_arn" {
  description = "IAM role ARN for delivery status success feedback for application endpoints."
  type        = string
  default     = null
}

variable "application_success_feedback_sample_rate" {
  description = "Percentage of successful deliveries to sample for application endpoint feedback. Valid values are 0-100."
  type        = number
  default     = null
}

variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO topics."
  type        = bool
  default     = false
}

variable "delivery_policy" {
  description = "JSON string for the SNS topic delivery policy."
  type        = string
  default     = null
}

variable "display_name" {
  description = "Display name for the SNS topic. Used as the sender name in email notifications."
  type        = string
  default     = null
}

variable "fifo_topic" {
  description = "Whether to create a FIFO (first-in, first-out) topic. When true, the topic name will have '.fifo' appended automatically."
  type        = bool
  default     = false
}

variable "firehose_failure_feedback_role_arn" {
  description = "IAM role ARN for delivery status failure feedback for Firehose endpoints."
  type        = string
  default     = null
}

variable "firehose_success_feedback_role_arn" {
  description = "IAM role ARN for delivery status success feedback for Firehose endpoints."
  type        = string
  default     = null
}

variable "firehose_success_feedback_sample_rate" {
  description = "Percentage of successful deliveries to sample for Firehose endpoint feedback. Valid values are 0-100."
  type        = number
  default     = null
}

variable "http_failure_feedback_role_arn" {
  description = "IAM role ARN for delivery status failure feedback for HTTP/HTTPS endpoints."
  type        = string
  default     = null
}

variable "http_success_feedback_role_arn" {
  description = "IAM role ARN for delivery status success feedback for HTTP/HTTPS endpoints."
  type        = string
  default     = null
}

variable "http_success_feedback_sample_rate" {
  description = "Percentage of successful deliveries to sample for HTTP/HTTPS endpoint feedback. Valid values are 0-100."
  type        = number
  default     = null
}

variable "kms_master_key_id" {
  description = "ID of the AWS KMS key to use for server-side encryption of the SNS topic. Use 'alias/aws/sns' for the AWS-managed key. Defaults to the AWS-managed SNS key for encryption at rest."
  type        = string
  default     = "alias/aws/sns"
}

variable "lambda_failure_feedback_role_arn" {
  description = "IAM role ARN for delivery status failure feedback for Lambda endpoints."
  type        = string
  default     = null
}

variable "lambda_success_feedback_role_arn" {
  description = "IAM role ARN for delivery status success feedback for Lambda endpoints."
  type        = string
  default     = null
}

variable "lambda_success_feedback_sample_rate" {
  description = "Percentage of successful deliveries to sample for Lambda endpoint feedback. Valid values are 0-100."
  type        = number
  default     = null
}

variable "name" {
  description = "Name of the SNS topic. Mutually exclusive with name_prefix. When fifo_topic is true, '.fifo' is appended automatically."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "Name prefix for the SNS topic. Mutually exclusive with name. A unique suffix is appended by AWS."
  type        = string
  default     = null
}

variable "policy" {
  description = "JSON string for the SNS topic access policy. When null, no topic policy is created and AWS defaults apply."
  type        = string
  default     = null
}

variable "signature_version" {
  description = "Signature version used for SNS notifications. Valid values are 1 (SHA1) or 2 (SHA256). Defaults to 1."
  type        = number
  default     = null
  validation {
    condition     = var.signature_version == null || var.signature_version == 1 || var.signature_version == 2
    error_message = "signature_version must be 1 or 2."
  }
}

variable "sqs_failure_feedback_role_arn" {
  description = "IAM role ARN for delivery status failure feedback for SQS endpoints."
  type        = string
  default     = null
}

variable "sqs_success_feedback_role_arn" {
  description = "IAM role ARN for delivery status success feedback for SQS endpoints."
  type        = string
  default     = null
}

variable "sqs_success_feedback_sample_rate" {
  description = "Percentage of successful deliveries to sample for SQS endpoint feedback. Valid values are 0-100."
  type        = number
  default     = null
}

variable "tracing_config" {
  description = "Tracing mode for the SNS topic. Valid values are PassThrough or Active."
  type        = string
  default     = null
  validation {
    condition     = var.tracing_config == null || var.tracing_config == "PassThrough" || var.tracing_config == "Active"
    error_message = "tracing_config must be PassThrough or Active."
  }
}

###########################
# SNS Topic Subscriptions
###########################

variable "subscriptions" {
  description = "Map of SNS topic subscriptions to create. The key is a logical name for the subscription."
  type = map(object({
    confirmation_timeout_in_minutes = optional(number, 1)
    delivery_policy                 = optional(string)
    endpoint                        = string
    endpoint_auto_confirms          = optional(bool, false)
    filter_policy                   = optional(string)
    filter_policy_scope             = optional(string)
    protocol                        = string
    raw_message_delivery            = optional(bool, false)
    redrive_policy                  = optional(string)
    replay_policy                   = optional(string)
    subscription_role_arn           = optional(string)
  }))
  default = {}
  # Example:
  # subscriptions = {
  #   ops_email = {
  #     protocol = "email"
  #     endpoint = "ops@example.com"
  #   }
  #   alerts_lambda = {
  #     protocol = "lambda"
  #     endpoint = "arn:aws:lambda:us-east-1:123456789012:function:my-function"
  #   }
  # }
}

###########################
# General Variables
###########################

variable "tags" {
  description = "A mapping of tags to assign to all resources."
  type        = map(string)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}
