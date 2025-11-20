###########################
# KMS Variables
###########################

variable "key_customer_master_key_spec" {
  description = "(Optional) Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1. Defaults to SYMMETRIC_DEFAULT. For help with choosing a key spec, see the AWS KMS Developer Guide."
  default     = "SYMMETRIC_DEFAULT"
  type        = string
  validation {
    condition     = can(regex("^(SYMMETRIC_DEFAULT|RSA_2048|RSA_3072|RSA_4096|ECC_NIST_P256|ECC_NIST_P384|ECC_NIST_P521|ECC_SECG_P256K1)$", var.key_customer_master_key_spec))
    error_message = "The value must be one of SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1."
  }
}

variable "key_description" {
  description = "(Optional) The description of the key as viewed in AWS console."
  default     = "CloudTrail kms key used to encrypt audit logs"
  type        = string
}

variable "key_deletion_window_in_days" {
  description = "(Optional) Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 30 days."
  default     = 30
  type        = number
  validation {
    condition     = can(regex("^[7-9]|[1-2][0-9]|30$", var.key_deletion_window_in_days))
    error_message = "The value must be between 7 and 30 days."
  }
}

variable "key_enable_key_rotation" {
  description = "(Optional) Specifies whether key rotation is enabled. Defaults to false."
  default     = true
  type        = bool
  validation {
    condition     = can(regex("true|false", var.key_enable_key_rotation))
    error_message = "The value must be true or false."
  }
}

variable "key_usage" {
  description = "(Optional) Specifies the intended use of the key. Defaults to ENCRYPT_DECRYPT, and only symmetric encryption and decryption are supported."
  default     = "ENCRYPT_DECRYPT"
  type        = string
  validation {
    condition     = can(regex("ENCRYPT_DECRYPT", var.key_usage))
    error_message = "The value must be ENCRYPT_DECRYPT."
  }
}

variable "key_is_enabled" {
  description = "(Optional) Specifies whether the key is enabled. Defaults to true."
  default     = true
  type        = string
  validation {
    condition     = can(regex("true|false", var.key_is_enabled))
    error_message = "The value must be true or false."
  }
}

######################
# S3 Variables
######################

variable "bucket_lifecycle_rule_id" {
  type        = string
  description = "(Required) Unique identifier for the rule. The value cannot be longer than 255 characters."
  default     = "365_day_delete"
}

variable "bucket_lifecycle_expiration_days" {
  type        = number
  description = "(Optional) The lifetime, in days, of the objects that are subject to the rule. The value must be a non-zero positive integer."
  default     = 365
  validation {
    condition     = can(regex("^[1-9][0-9]*$", var.bucket_lifecycle_expiration_days))
    error_message = "The value must be a non-zero positive integer."
  }
}

variable "versioning_status" {
  type        = string
  description = "(Required) The versioning state of the bucket. Valid values: Enabled, Suspended, or Disabled. Disabled should only be used when creating or importing resources that correspond to unversioned S3 buckets."
  default     = "Enabled"
  validation {
    condition     = can(regex("Enabled|Suspended|Disabled", var.versioning_status))
    error_message = "The value must be Enabled, Suspended, or Disabled."
  }
}

variable "bucket_key_enabled" {
  type        = bool
  description = "(Optional) Whether or not to use Amazon S3 Bucket Keys for SSE-KMS."
  default     = true
  validation {
    condition     = can(regex("true|false", var.bucket_key_enabled))
    error_message = "The value must be true or false."
  }
}

variable "force_destroy" {
  type        = bool
  description = "(Optional) A boolean that indicates all objects should be deleted from the S3 bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
  validation {
    condition     = can(regex("true|false", var.force_destroy))
    error_message = "The value must be true or false."
  }
}

variable "sse_algorithm" {
  type        = string
  description = "(Required) The server-side encryption algorithm to use. Valid values are AES256 and aws:kms"
  default     = "aws:kms"
  validation {
    condition     = can(regex("AES256|aws:kms", var.sse_algorithm))
    error_message = "The value must be AES256 or aws:kms."
  }
}

variable "mfa_delete" {
  type        = string
  description = "(Optional) Specifies whether MFA delete is enabled in the bucket versioning configuration. Valid values: Enabled or Disabled."
  default     = "Disabled"
  validation {
    condition     = can(regex("Enabled|Disabled", var.mfa_delete))
    error_message = "The value must be Enabled or Disabled."
  }
}

variable "target_bucket" {
  type        = string
  description = "(Optional) The name of the bucket that will receive the logs. Required if logging of the S3 bucket is set to true."
  default     = null
}

variable "target_prefix" {
  type        = string
  description = "(Optional) The prefix that is prepended to all log object keys. If not set, the logs are stored in the root of the bucket."
  default     = "log/"
}

###########################
# CloudWatch Log Group Variables
###########################

variable "cloudwatch_retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default     = 90
  type        = number
}

###########################
# IAM Policy
###########################

variable "iam_policy_description" {
  description = "(Optional, Forces new resource) Description of the IAM policy."
  default     = "Used with flow logs to send packet capture logs to a CloudWatch log group"
  type        = string
}

variable "iam_policy_name_prefix" {
  description = "(Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name."
  default     = "cloudtrail_policy_"
  type        = string
}

variable "iam_policy_path" {
  type        = string
  description = "(Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information."
  default     = "/"
}

###########################
# IAM Role Variables
###########################

variable "iam_role_assume_role_policy" {
  type        = string
  description = "(Required) The policy that grants an entity permission to assume the role."
  default     = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

variable "iam_role_description" {
  type        = string
  description = "(Optional) The description of the role."
  default     = "Role utilized by CloudTrail to write CloudWatch logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"
}

variable "iam_role_force_detach_policies" {
  type        = bool
  description = "(Optional) Specifies to force detaching any policies the role has before destroying it. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.iam_role_force_detach_policies))
    error_message = "The value must be true or false."
  }
}

variable "iam_role_max_session_duration" {
  type        = number
  description = "(Optional) The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
  default     = 3600
  validation {
    condition     = var.iam_role_max_session_duration >= 3600 && var.iam_role_max_session_duration <= 43200
    error_message = "The value must be a non-zero positive integer between 1 and 12 hours, or 3600 and 43200 seconds."
  }
}

variable "iam_role_name_prefix" {
  type        = string
  description = "(Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name."
  default     = "cloudtrail_role_"
}

variable "iam_role_permissions_boundary" {
  type        = string
  description = "(Optional) The ARN of the policy that is used to set the permissions boundary for the role."
  default     = null
}

###########################
# CloudTrail Variables
###########################

variable "name" {
  description = "Name of the trail"
  type        = string
  default     = "cloudtrail"
  validation {
    condition     = can(regex("^[a-zA-Z0-9-]+$", var.name))
    error_message = "The value must be alphanumeric with dashes. No underscores allowed due to S3 bucket naming requirements."
  }
}

variable "include_global_service_events" {
  type        = bool
  description = "Specifies whether the trail is publishing events from global services such as IAM to the log files"
  default     = true
  validation {
    condition     = can(regex("true|false", var.include_global_service_events))
    error_message = "The value must be true or false."
  }
}

variable "is_multi_region_trail" {
  type        = bool
  description = "Determines whether or not the cloudtrail is created for all regions"
  default     = true
  validation {
    condition     = can(regex("true|false", var.is_multi_region_trail))
    error_message = "The value must be true or false."
  }
}

variable "is_organization_trail" {
  type        = bool
  description = "(Optional) Whether the trail is an AWS Organizations trail. Organization trails log events for the master account and all member accounts. Can only be created in the organization master account. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.is_organization_trail))
    error_message = "The value must be true or false."
  }
}

variable "enable_log_file_validation" {
  type        = bool
  description = "Enabled log file validation to all logs sent to S3"
  default     = true
  validation {
    condition     = can(regex("true|false", var.enable_log_file_validation))
    error_message = "The value must be true or false."
  }
}

######################
# Global Variables
######################

variable "enable_s3_bucket_logging" {
  type        = bool
  description = "(Optional) Enable logging on the cloudtrail S3 bucket. If true, the 'target_bucket' is required. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("true|false", var.enable_s3_bucket_logging))
    error_message = "The value must be true or false."
  }
}

variable "tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = null
}
