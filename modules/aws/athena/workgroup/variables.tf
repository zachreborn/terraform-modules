###########################
# Workgroup Variables
###########################

variable "name" {
  type        = string
  description = "(Required) Name of the workgroup."
  validation {
    condition     = can(regex("^[a-zA-Z0-9._-]{1,128}$", var.name))
    error_message = "The workgroup name must be 1-128 characters and contain only letters, numbers, periods, underscores, or hyphens."
  }
}

variable "description" {
  type        = string
  description = "(Optional) Description of the workgroup."
  default     = null
}

variable "state" {
  type        = string
  description = "(Optional) State of the workgroup. Valid values are ENABLED or DISABLED. Defaults to ENABLED."
  default     = "ENABLED"
  validation {
    condition     = contains(["ENABLED", "DISABLED"], var.state)
    error_message = "The state must be ENABLED or DISABLED."
  }
}

variable "force_destroy" {
  type        = bool
  description = "(Optional) Option to delete the workgroup and its contents even if the workgroup contains any named queries. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", var.force_destroy))
    error_message = "force_destroy must be true or false."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Map of tags to assign to the resource."
  default     = {}
}

###########################
# Configuration Variables
###########################

variable "enable_minimum_encryption_configuration" {
  type        = bool
  description = "(Optional) Boolean indicating whether a minimum level of encryption is enforced for the workgroup for query and calculation results written to Amazon S3. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", var.enable_minimum_encryption_configuration))
    error_message = "enable_minimum_encryption_configuration must be true or false."
  }
}

variable "execution_role" {
  type        = string
  description = "(Optional) Role used to access user resources in notebook sessions and IAM Identity Center enabled workgroups. Required for IAM Identity Center enabled workgroups."
  default     = null
}

variable "requester_pays_enabled" {
  type        = bool
  description = "(Optional) If true, allows workgroup members to reference Amazon S3 Requester Pays buckets in queries. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", var.requester_pays_enabled))
    error_message = "requester_pays_enabled must be true or false."
  }
}

variable "selected_engine_version" {
  type        = string
  description = "(Optional) Requested Athena engine version. Defaults to AUTO if not set. See https://docs.aws.amazon.com/athena/latest/ug/engine-versions.html."
  default     = null
}

variable "bytes_scanned_cutoff_per_query" {
  type        = number
  description = "(Optional) Integer for the upper data usage limit (cutoff) for the amount of bytes a single query in a workgroup is allowed to scan. Must be at least 10485760 (10 MB). A value of null disables the cutoff."
  default     = null
  validation {
    condition     = var.bytes_scanned_cutoff_per_query == null ? true : var.bytes_scanned_cutoff_per_query >= 10485760
    error_message = "bytes_scanned_cutoff_per_query must be null or at least 10485760 (10 MB)."
  }
}

variable "enforce_workgroup_configuration" {
  type        = bool
  description = "(Optional) Boolean whether the settings for the workgroup, which include limits on the amount of data each query or the entire workgroup can process and the encryption configuration, are overridden by the client-side settings. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.enforce_workgroup_configuration))
    error_message = "enforce_workgroup_configuration must be true or false."
  }
}

variable "publish_cloudwatch_metrics_enabled" {
  type        = bool
  description = "(Optional) Boolean whether Amazon CloudWatch metrics are enabled for the workgroup. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.publish_cloudwatch_metrics_enabled))
    error_message = "publish_cloudwatch_metrics_enabled must be true or false."
  }
}

###########################
# Result Configuration Variables
###########################

variable "expected_bucket_owner" {
  type        = string
  description = "(Optional) AWS account ID expected to own the S3 bucket where query results are stored. Used to prevent data exfiltration."
  default     = null
}

variable "s3_acl_option" {
  type        = string
  description = "(Optional) Amazon S3 canned ACL to set on stored query results. Valid value is BUCKET_OWNER_FULL_CONTROL. If null, no ACL configuration is applied."
  default     = null
  validation {
    condition     = var.s3_acl_option == null ? true : var.s3_acl_option == "BUCKET_OWNER_FULL_CONTROL"
    error_message = "s3_acl_option must be BUCKET_OWNER_FULL_CONTROL or null."
  }
}

variable "output_location" {
  type        = string
  description = "(Optional) The location in Amazon S3 where your query results are stored, such as s3://path/to/query/bucket/. If null, no default output location is set."
  default     = null
}

variable "encryption_option" {
  type        = string
  description = "(Optional) Indicates whether Amazon S3 server-side encryption with Amazon S3-managed keys (SSE_S3), server-side encryption with KMS-managed keys (SSE_KMS), or client-side encryption with KMS-managed keys (CSE_KMS) is used. If null, no encryption configuration is applied."
  default     = null
  validation {
    condition     = var.encryption_option == null ? true : contains(["SSE_S3", "SSE_KMS", "CSE_KMS"], var.encryption_option)
    error_message = "encryption_option must be SSE_S3, SSE_KMS, CSE_KMS, or null."
  }
}

variable "kms_key_arn" {
  type        = string
  description = "(Optional) For SSE_KMS and CSE_KMS, the ARN of the KMS key used to encrypt query results. Required when encryption_option is SSE_KMS or CSE_KMS."
  default     = null
}
