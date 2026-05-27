###########################
# General Variables
###########################
variable "name" {
  type        = string
  description = "(Required) A name used as the Name tag on all taggable resources created by this module."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of additional tags to assign to all taggable resources. Merged with a Name tag derived from var.name."
  default     = {}
}

###########################
# Organizations Variables
###########################
variable "admin_account_id" {
  type        = string
  description = "(Required) The AWS account ID to register as the delegated administrator for AWS Config in the organization."
  validation {
    condition     = can(regex("^\\d{12}$", var.admin_account_id))
    error_message = "The value of admin_account_id must be a 12-digit AWS account ID."
  }
}

###########################
# Config Recorder Variables
###########################
variable "recorder_name" {
  type        = string
  description = "(Optional) The name of the AWS Config configuration recorder. Only one recorder per region is allowed. Defaults to 'default'."
  default     = "default"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,256}$", var.recorder_name))
    error_message = "The recorder_name must be 1-256 alphanumeric characters, hyphens, or underscores."
  }
}

variable "recorder_role_arn" {
  type        = string
  description = "(Required) ARN of the IAM role that AWS Config uses to record and deliver configuration changes. Must have the AWSConfigRole managed policy or equivalent permissions."
  validation {
    condition     = can(regex("^arn:aws[a-z-]*:iam::\\d{12}:role/.+$", var.recorder_role_arn))
    error_message = "The recorder_role_arn must be a valid IAM role ARN."
  }
}

variable "all_supported" {
  type        = bool
  description = "(Optional) Specifies whether AWS Config records configuration changes for every supported type of regional resource. Defaults to true. Set to false when using resource_types for inclusion-based recording."
  default     = true
}

variable "include_global_resource_types" {
  type        = bool
  description = "(Optional) Specifies whether AWS Config includes all supported types of global resources (e.g., IAM) with the resources it records. Only valid when all_supported is true. Defaults to true."
  default     = true
}

variable "resource_types" {
  type        = list(string)
  description = "(Optional) A list of resource types to include for recording when using INCLUSION_BY_RESOURCE_TYPES recording strategy. Leave empty when all_supported is true."
  default     = []
}

variable "exclusion_resource_types" {
  type        = list(string)
  description = "(Optional) A list of resource types to exclude from recording when using EXCLUSION_BY_RESOURCE_TYPES recording strategy. Leave empty when all_supported is true and no exclusions are needed."
  default     = []
}

variable "recording_strategy" {
  type        = string
  description = "(Optional) The recording strategy for the recorder. Valid values: ALL_SUPPORTED_RESOURCE_TYPES, EXCLUSION_BY_RESOURCE_TYPES, INCLUSION_BY_RESOURCE_TYPES. Defaults to null (provider uses ALL_SUPPORTED_RESOURCE_TYPES)."
  default     = null
  validation {
    condition     = var.recording_strategy == null ? true : contains(["ALL_SUPPORTED_RESOURCE_TYPES", "EXCLUSION_BY_RESOURCE_TYPES", "INCLUSION_BY_RESOURCE_TYPES"], var.recording_strategy)
    error_message = "The recording_strategy must be one of: ALL_SUPPORTED_RESOURCE_TYPES, EXCLUSION_BY_RESOURCE_TYPES, INCLUSION_BY_RESOURCE_TYPES, or null."
  }
}

variable "recording_frequency" {
  type        = string
  description = "(Optional) The recording frequency for the recorder. Valid values: CONTINUOUS, DAILY. Defaults to CONTINUOUS."
  default     = "CONTINUOUS"
  validation {
    condition     = var.recording_frequency == null ? true : contains(["CONTINUOUS", "DAILY"], var.recording_frequency)
    error_message = "The recording_frequency must be CONTINUOUS, DAILY, or null."
  }
}

###########################
# Delivery Channel Variables
###########################
variable "delivery_channel_name" {
  type        = string
  description = "(Optional) The name of the AWS Config delivery channel. Defaults to 'default'."
  default     = "default"
  validation {
    condition     = can(regex("^[a-zA-Z0-9_-]{1,256}$", var.delivery_channel_name))
    error_message = "The delivery_channel_name must be 1-256 alphanumeric characters, hyphens, or underscores."
  }
}

variable "delivery_frequency" {
  type        = string
  description = "(Optional) The frequency with which AWS Config delivers configuration snapshots to the S3 bucket. Valid values: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours. Defaults to TwentyFour_Hours."
  default     = "TwentyFour_Hours"
  validation {
    condition     = contains(["One_Hour", "Three_Hours", "Six_Hours", "Twelve_Hours", "TwentyFour_Hours"], var.delivery_frequency)
    error_message = "The delivery_frequency must be one of: One_Hour, Three_Hours, Six_Hours, Twelve_Hours, TwentyFour_Hours."
  }
}

variable "s3_kms_key_arn" {
  type        = string
  description = "(Optional) The ARN of the AWS KMS key used to encrypt objects delivered by AWS Config to the S3 delivery bucket. Set to null to use the bucket's default encryption. Defaults to null."
  default     = null
  validation {
    condition     = var.s3_kms_key_arn == null ? true : can(regex("^arn:aws[a-z-]*:kms:[a-z0-9-]+:\\d{12}:key/.+$", var.s3_kms_key_arn))
    error_message = "The s3_kms_key_arn must be a valid KMS key ARN or null."
  }
}

variable "sns_topic_arn" {
  type        = string
  description = "(Optional) The ARN of the SNS topic to which AWS Config sends notifications about configuration changes and compliance. Set to null to disable SNS notifications."
  default     = null
  validation {
    condition     = var.sns_topic_arn == null ? true : can(regex("^arn:aws[a-z-]*:sns:[a-z0-9-]+:\\d{12}:.+$", var.sns_topic_arn))
    error_message = "The sns_topic_arn must be a valid SNS topic ARN or null."
  }
}

###########################
# S3 Bucket Variables
###########################
variable "create_s3_bucket" {
  type        = bool
  description = "(Optional) If true, creates a new S3 bucket for AWS Config delivery. If false, the s3_bucket_name variable must reference an existing bucket. Defaults to true."
  default     = true
}

variable "s3_bucket_name" {
  type        = string
  description = "(Optional) The name of an existing S3 bucket to use for AWS Config delivery when create_s3_bucket is false. Must be set when create_s3_bucket is false."
  default     = null
  validation {
    condition     = var.s3_bucket_name == null ? true : can(regex("^[a-z0-9][a-z0-9.\\-]{1,61}[a-z0-9]$", var.s3_bucket_name))
    error_message = "The s3_bucket_name must be a valid S3 bucket name (lowercase, 3-63 characters) or null."
  }
}

variable "s3_bucket_prefix" {
  type        = string
  description = "(Optional) Name prefix for the S3 bucket created when create_s3_bucket is true. AWS will append a unique suffix to ensure global uniqueness. Defaults to 'config-'."
  default     = "config-"
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.\\-]{0,36}$", var.s3_bucket_prefix))
    error_message = "The s3_bucket_prefix must be lowercase alphanumeric, hyphens, or periods, and no more than 37 characters."
  }
}

variable "s3_bucket_force_destroy" {
  type        = bool
  description = "(Optional) If true, all objects are deleted from the bucket when the bucket is destroyed, allowing the bucket to be destroyed without error. Defaults to false."
  default     = false
}

variable "s3_bucket_object_lock_enabled" {
  type        = bool
  description = "(Optional) Indicates whether this bucket has Object Lock enabled. Valid values are true or false. Defaults to false."
  default     = false
}

variable "s3_key_prefix" {
  type        = string
  description = "(Optional) The S3 key prefix (folder path) within the delivery bucket where AWS Config stores configuration snapshots and history files. Set to null to store at bucket root."
  default     = null
}

variable "enable_s3_bucket_logging" {
  type        = bool
  description = "(Optional) If true, enables S3 server access logging for the Config delivery bucket. Requires s3_logging_target_bucket to be set. Defaults to false."
  default     = false
}

variable "s3_logging_target_bucket" {
  type        = string
  description = "(Optional) The name of the S3 bucket to receive server access logs from the Config delivery bucket. Required when enable_s3_bucket_logging is true."
  default     = null
}

variable "s3_logging_target_prefix" {
  type        = string
  description = "(Optional) A prefix for all log object keys when S3 server access logging is enabled. Defaults to null."
  default     = null
}

###########################
# Conformance Pack Variables
###########################
variable "enable_conformance_packs" {
  type        = bool
  description = "(Optional) If true, deploys the organization conformance packs defined in the conformance_packs variable. Defaults to false."
  default     = false
}

variable "conformance_packs" {
  type = list(object({
    name              = string
    template_s3_uri   = optional(string)
    template_body     = optional(string)
    excluded_accounts = optional(list(string), [])
    input_parameters = optional(list(object({
      parameter_name  = string
      parameter_value = string
    })), [])
  }))
  description = "(Optional) List of organization conformance packs to deploy. Each object requires a name and either template_s3_uri or template_body. Optionally supply excluded_accounts (list of account IDs to exclude) and input_parameters (list of name/value pairs to pass to the template). Only used when enable_conformance_packs is true."
  default     = []
}

variable "conformance_pack_delivery_s3_bucket" {
  type        = string
  description = "(Optional) The name of the S3 bucket where AWS Config stores conformance pack templates and results. Set to null to use the main delivery bucket."
  default     = null
}

variable "conformance_pack_delivery_s3_key_prefix" {
  type        = string
  description = "(Optional) The prefix for the S3 key where conformance pack templates and results are stored. Defaults to null."
  default     = null
}
