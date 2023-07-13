##############################
# EFS File System Variables
##############################
variable "availability_zone_name" {
  description = "(Optional) the AWS Availability Zone in which to create the file system. Used to create a file system that uses One Zone storage classes. See user guide for more information - https://docs.aws.amazon.com/efs/latest/ug/storage-classes.html"
  type        = string
  default     = null
}

variable "creation_token" {
  description = "(Optional) A unique name (a maximum of 64 characters are allowed) used as reference when creating the Elastic File System to ensure idempotent file system creation. By default generated by Terraform. See user guide for more information - http://docs.aws.amazon.com/efs/latest/ug/"
  type        = string
  default     = null
  validation {
    condition     = length(var.creation_token) <= 64
    error_message = "The creation_token must be less than or equal to 64 characters."
  }
}

variable "encrypted" {
  description = "(Optional) If true, the disk will be encrypted."
  type        = bool
  default     = true
  validation {
    condition     = var.encrypted == true || var.encrypted == false
    error_message = "The encrypted must be true or false."
  }
}

variable "kms_key_id" {
  description = "(Optional) The ARN for the KMS encryption key. If not set, but encrypted is set to true the module will generate a unique KMS key. When specifying kms_key_id, encrypted needs to be set to true."
  type        = string
  default     = null
}

variable "lifecycle_policy" {
  description = "(Optional) A file system lifecycle policy object. By default, no policy is used. See user guide for more information - https://docs.aws.amazon.com/efs/latest/ug/API_LifecyclePolicy.html"
  type = list(object({
    transition_to_ia                    = string
    transition_to_primary_storage_class = string
  }))
  default = []

  # Example:
  # lifecycle_policy = [
  #     {
  #         transition_to_ia                    = "AFTER_30_DAYS"
  #         transition_to_primary_storage_class = "AFTER_14_DAYS"
  #     }
  # ]
  #
}

variable "performance_mode" {
  description = "(Optional) The file system performance mode. Can be either 'generalPurpose' or 'maxIO'. Defaults to 'generalPurpose'."
  type        = string
  default     = "generalPurpose"
  validation {
    condition     = var.performance_mode == "generalPurpose" || var.performance_mode == "maxIO"
    error_message = "The performance_mode must be generalPurpose or maxIO."
  }
}

variable "provisioned_throughput_in_mibps" {
  description = "(Optional) The throughput, measured in MiB/s, that you want to provision for the file system. Only applicable with throughput_mode set to provisioned. Valid values are 1-1024. Required if throughput_mode is set to provisioned."
  type        = number
  default     = null
  validation {
    condition     = var.provisioned_throughput_in_mibps == null ? true : (var.provisioned_throughput_in_mibps >= 1 && var.provisioned_throughput_in_mibps <= 1024)
    error_message = "The provisioned_throughput_in_mibps must be between 1 and 1024."
  }
}

variable "throughput_mode" {
  description = "(Optional) Throughput mode for the file system. Defaults to bursting. Valid values: bursting, provisioned, or elastic. When using provisioned, also set provisioned_throughput_in_mibps."
  type        = string
  default     = "bursting"
  validation {
    condition     = var.throughput_mode == "bursting" || var.throughput_mode == "provisioned" || var.throughput_mode == "elastic"
    error_message = "The throughput_mode must be bursting, provisioned, or elastic."
  }
}

##############################
# EFS Mount Target Variables
##############################
variable "subnet_ids" {
  description = "(Required) A list of subnet IDs where you want to create the mount target."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) > 0
    error_message = "The subnet_ids must be at least 1 element."
  }
}

variable "security_groups" {
  description = "(Optional) A list of up to 5 VPC security group IDs (that must be for the same VPC as subnet_ids) in effect for the mount target."
  type        = list(string)
  default     = []
}

##############################
# General Variables
##############################

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the file system."
  type        = map(string)
  default     = {
    terraform = "true"
  }
}