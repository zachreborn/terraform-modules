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

variable "include_global_resource_types" {
  type        = bool
  description = "(Optional) Specifies whether AWS Config includes all supported types of global resources (e.g., IAM) with the resources it records. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.include_global_resource_types))
    error_message = "The value must be true or false."
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
  validation {
    condition     = can(regex("^(true|false)$", var.create_s3_bucket))
    error_message = "The value must be true or false."
  }
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

variable "s3_key_prefix" {
  type        = string
  description = "(Optional) The S3 key prefix (folder path) within the delivery bucket where AWS Config stores configuration snapshots and history files. Set to null to store at bucket root."
  default     = null
}

###########################
# Conformance Pack Variables
###########################
variable "enable_conformance_packs" {
  type        = bool
  description = "(Optional) If true, deploys the organization conformance packs defined in the conformance_packs variable. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", var.enable_conformance_packs))
    error_message = "The value must be true or false."
  }
}

variable "conformance_packs" {
  type = list(object({
    name            = string
    template_s3_uri = optional(string)
    template_body   = optional(string)
  }))
  description = "(Optional) List of organization conformance packs to deploy. Each object requires a name, and either a template_s3_uri (S3 URI to a conformance pack template) or template_body (inline YAML template). Only used when enable_conformance_packs is true."
  default     = []
}

###########################
# General Variables
###########################
variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to all taggable resources created by this module."
  default = {
    created_by  = "<YOUR NAME>"
    environment = "prod"
    terraform   = "true"
  }
}
