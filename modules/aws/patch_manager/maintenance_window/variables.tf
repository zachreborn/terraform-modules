###########################
# Maintenance Window Variables
###########################

variable "name" {
  description = "(Required) The name of the maintenance window. Must contain only letters, numbers, underscores, hyphens, and periods (3-128 characters). This value also seeds task and IAM role names, so keep it concise."
  type        = string
}

variable "description" {
  description = "(Optional) The description of the maintenance window."
  type        = string
  default     = null
}

variable "schedule" {
  description = "(Optional) The schedule of the maintenance window in cron or rate expression format. Defaults to the 3rd Friday of every month at midnight (evaluated in schedule_timezone)."
  type        = string
  default     = "cron(0 0 ? * FRI#3 *)"
}

variable "schedule_timezone" {
  description = "(Optional) IANA Time Zone Database timezone for the schedule (e.g., America/Denver for Mountain Time, which handles both MST UTC-7 and MDT UTC-6 automatically)."
  type        = string
  default     = "America/Denver"
}

variable "schedule_offset" {
  description = "(Optional) Number of days to wait after the CRON expression date before running the maintenance window. Valid range: 1-6."
  type        = number
  default     = null
}

variable "duration" {
  description = "(Optional) The duration of the maintenance window in hours. Defaults to 5 hours (12am-5am)."
  type        = number
  default     = 5
}

variable "cutoff" {
  description = "(Optional) The number of hours before the end of the window that Systems Manager stops scheduling new tasks. Must be less than duration."
  type        = number
  default     = 1
}

variable "allow_unassociated_targets" {
  description = "(Optional) Whether targets must be registered with the maintenance window before tasks can be defined. Set to true to allow targeting instances not explicitly registered."
  type        = bool
  default     = false
}

variable "enabled" {
  description = "(Optional) Whether the maintenance window is enabled."
  type        = bool
  default     = true
}

variable "start_date" {
  description = "(Optional) ISO-8601 timestamp after which the maintenance window becomes active."
  type        = string
  default     = null
}

variable "end_date" {
  description = "(Optional) ISO-8601 timestamp after which the maintenance window is no longer active."
  type        = string
  default     = null
}

###########################
# Target Variables
###########################

variable "targets" {
  description = "(Required) Map of maintenance window target configurations. Map keys are used as target names and must match the pattern ^[a-zA-Z0-9_\\-.]{3,128}$. Each entry performs tag-based instance selection. A single patch group tag key/value pair per target is required."
  type = map(object({
    description       = string
    resource_type     = string
    owner_information = string
    tag_key           = string
    tag_values        = list(string)
  }))
}

###########################
# Task Variables
###########################

variable "patch_operation" {
  description = "(Optional) The patch operation to perform. Install applies approved patches; Scan checks compliance without applying patches."
  type        = string
  default     = "Install"
  validation {
    condition     = contains(["Install", "Scan"], var.patch_operation)
    error_message = "patch_operation must be either Install or Scan."
  }
}

variable "reboot_option" {
  description = "(Optional) The reboot behavior after patching. RebootIfNeeded reboots only when required by a patch; NoReboot skips reboots."
  type        = string
  default     = "RebootIfNeeded"
  validation {
    condition     = contains(["RebootIfNeeded", "NoReboot"], var.reboot_option)
    error_message = "reboot_option must be either RebootIfNeeded or NoReboot."
  }
}

variable "task_priority" {
  description = "(Optional) The priority of the maintenance window task. Lower numbers run first."
  type        = number
  default     = 1
}

variable "max_concurrency" {
  description = "(Optional) The maximum number of targets this task can be run for in parallel, as an integer or percentage string (e.g., '10' or '10%')."
  type        = string
  default     = "10%"
}

variable "max_errors" {
  description = "(Optional) The maximum number of errors allowed before this task stops being scheduled, as an integer or percentage string (e.g., '5' or '5%')."
  type        = string
  default     = "5%"
}

variable "timeout_seconds" {
  description = "(Optional) The timeout in seconds for the Run Command task. Defaults to 1 hour."
  type        = number
  default     = 3600
}

variable "document_hash" {
  description = "(Optional) The SHA-256 or SHA-1 hash of the document content to verify integrity."
  type        = string
  default     = null
}

variable "document_hash_type" {
  description = "(Optional) The hash type. Valid values: Sha256, Sha1. Required when document_hash is set."
  type        = string
  default     = "Sha256"
  validation {
    condition     = contains(["Sha256", "Sha1"], var.document_hash_type)
    error_message = "document_hash_type must be either Sha256 or Sha1."
  }
}

variable "document_version" {
  description = "(Optional) The version of the SSM document to use. Defaults to the latest version."
  type        = string
  default     = null
}

variable "task_comment" {
  description = "(Optional) A comment to include in the task invocation for auditing purposes."
  type        = string
  default     = null
}

###########################
# S3 Logging Variables
###########################

variable "enable_s3_logging" {
  description = "(Optional) Whether to write Run Command output to S3. Requires either create_s3_bucket = true or s3_bucket_name to be provided. Note: the instance profile used by managed instances must have s3:PutObject permission on the target bucket."
  type        = bool
  default     = false
}

variable "create_s3_bucket" {
  description = "(Optional) Whether to create an S3 bucket for patch run command output. The bucket name is auto-generated as <name>-patch-logs-<account_id> unless s3_bucket_name is provided."
  type        = bool
  default     = false
}

variable "s3_bucket_name" {
  description = "(Optional) Name of an existing S3 bucket for patch logs, or a custom name when create_s3_bucket = true. Must be globally unique. Required when enable_s3_logging = true and create_s3_bucket = false."
  type        = string
  default     = null
}

variable "s3_key_prefix" {
  description = "(Optional) The S3 key prefix (folder path) for patch log output."
  type        = string
  default     = "patch-logs"
}

variable "s3_log_retention_days" {
  description = "(Optional) Number of days to retain patch logs in S3 before expiration. Applies only when create_s3_bucket = true."
  type        = number
  default     = 90
}

variable "s3_kms_key_arn" {
  description = "(Optional) ARN of a KMS key for S3 server-side encryption. If null, AES-256 (SSE-S3) is used. Applies only when create_s3_bucket = true."
  type        = string
  default     = null
}

###########################
# SNS Notification Variables
###########################

variable "enable_sns_notification" {
  description = "(Optional) Whether to send SNS notifications for patch task events. Requires either create_sns_topic = true or sns_topic_arn to be provided."
  type        = bool
  default     = false
}

variable "create_sns_topic" {
  description = "(Optional) Whether to create an SNS topic for patch notifications. Topic name will be <name>-patch-notifications."
  type        = bool
  default     = false
}

variable "sns_topic_arn" {
  description = "(Optional) ARN of an existing SNS topic for notifications. Required when enable_sns_notification = true and create_sns_topic = false."
  type        = string
  default     = null
}

variable "sns_kms_key_id" {
  description = "(Optional) The ID of a KMS key to use for SNS topic encryption. Applies only when create_sns_topic = true."
  type        = string
  default     = null
}

variable "notification_events" {
  description = "(Optional) The patch task events that trigger an SNS notification. Valid values: All, InProgress, Success, TimedOut, Cancelled, Failed."
  type        = list(string)
  default     = ["All"]
}

variable "notification_type" {
  description = "(Optional) The notification type. Command sends one notification for the overall task; Invocation sends one per instance (can be high-volume at scale)."
  type        = string
  default     = "Command"
  validation {
    condition     = contains(["Command", "Invocation"], var.notification_type)
    error_message = "notification_type must be either Command or Invocation."
  }
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to all created resources."
  type        = map(any)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}
