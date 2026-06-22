###########################
# Storage Gateway
###########################

variable "activation_key" {
  type        = string
  description = "(Optional) Gateway activation key obtained after deploying and powering on the on-premises gateway VM. Mutually exclusive with gateway_ip_address; supply exactly one. Use this when you have already retrieved the activation key out of band. Stored in Terraform state in plaintext."
  default     = null
}

variable "average_download_rate_limit_in_bits_per_sec" {
  type        = number
  description = "(Optional) The average download bandwidth rate limit in bits per second. Defaults to null (no limit)."
  default     = null
}

variable "average_upload_rate_limit_in_bits_per_sec" {
  type        = number
  description = "(Optional) The average upload bandwidth rate limit in bits per second. Defaults to null (no limit)."
  default     = null
}

variable "cloudwatch_log_group_arn" {
  type        = string
  description = "(Optional) ARN of an existing CloudWatch log group to use for gateway health logs. When null and create_cloudwatch_log_group is true, this module creates one. Defaults to null."
  default     = null
}

variable "gateway_ip_address" {
  type        = string
  description = "(Optional) IP address of the gateway VM, used to fetch the activation key automatically during apply. Mutually exclusive with activation_key; supply exactly one. The VM must be reachable from where Terraform runs. Defaults to null."
  default     = null
}

variable "gateway_name" {
  type        = string
  description = "(Required) Name of the gateway. Also used as the Name tag."
}

variable "gateway_timezone" {
  type        = string
  description = "(Optional) Time zone for the gateway, in the format GMT, GMT-hh:mm, or GMT+hh:mm (e.g. GMT-7:00). Defaults to GMT."
  default     = "GMT"
}

variable "gateway_type" {
  type        = string
  description = "(Optional) Type of the gateway. This module manages file gateways, so valid values are FILE_FSX_SMB and FILE_S3. Defaults to FILE_FSX_SMB. File system associations require FILE_FSX_SMB."
  default     = "FILE_FSX_SMB"
  validation {
    condition     = contains(["FILE_FSX_SMB", "FILE_S3"], var.gateway_type)
    error_message = "The value of gateway_type must be one of FILE_FSX_SMB or FILE_S3."
  }
}

variable "gateway_vpc_endpoint" {
  type        = string
  description = "(Optional) VPC endpoint DNS name to use for the gateway's connection to the Storage Gateway service when using a private (VPC) endpoint. Defaults to null."
  default     = null
}

variable "maintenance_start_time" {
  type = object({
    hour_of_day    = number
    minute_of_hour = optional(number)
    day_of_week    = optional(number)
    day_of_month   = optional(number)
  })
  description = "(Optional) Weekly or monthly maintenance window. hour_of_day (0-23) and minute_of_hour (0-59); day_of_week (0-6, Sunday=0) for a weekly window or day_of_month (1-28) for a monthly window. Defaults to null, which lets the gateway pick a window."
  default     = null
}

variable "smb_active_directory_settings" {
  type = object({
    domain_name         = string
    password            = string
    username            = string
    domain_controllers  = optional(list(string))
    organizational_unit = optional(string)
    timeout_in_seconds  = optional(number)
  })
  description = "(Optional) Microsoft Active Directory join settings for SMB access. Required to associate an FSx for Windows file system on a FILE_FSX_SMB gateway. domain_name, username, and password are the join credentials; domain_controllers, organizational_unit, and timeout_in_seconds are optional. The password is stored in Terraform state in plaintext. Defaults to null."
  default     = null
}

variable "smb_file_share_visibility" {
  type        = bool
  description = "(Optional) Whether file shares on this gateway are visible when listing shares for the gateway's domain. Defaults to null, which uses the service default."
  default     = null
}

variable "smb_guest_password" {
  type        = string
  description = "(Optional) Guest password for guest access to SMB file shares. Stored in Terraform state in plaintext. Defaults to null."
  default     = null
}

variable "smb_security_strategy" {
  type        = string
  description = "(Optional) Specifies the type of security strategy for the gateway. Valid values are ClientSpecified, MandatorySigning, and MandatoryEncryption. Defaults to null, which uses the service default."
  default     = null
  validation {
    condition     = var.smb_security_strategy == null ? true : contains(["ClientSpecified", "MandatorySigning", "MandatoryEncryption"], var.smb_security_strategy)
    error_message = "The value of smb_security_strategy must be null, ClientSpecified, MandatorySigning, or MandatoryEncryption."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources created by this module."
  default     = {}
}

###########################
# Cache Disks
###########################

variable "cache_disk_ids" {
  type        = set(string)
  description = "(Optional) Set of local disk IDs (as reported by the gateway, e.g. via the aws_storagegateway_local_disk data source) to allocate as cache storage. Defaults to an empty set."
  default     = []
}

###########################
# File System Associations
###########################

variable "file_system_associations" {
  type = map(object({
    location_arn          = string
    password              = string
    username              = string
    audit_destination_arn = optional(string)
    cache_attributes = optional(object({
      cache_stale_timeout_in_seconds = optional(number)
    }))
  }))
  description = "(Optional) Map of FSx for Windows File Server associations keyed by a logical name. Per association: location_arn (the FSx for Windows file system ARN — e.g. the arn output of the fsx module), username/password (a domain user with access to the file system; password is stored in state in plaintext), optional audit_destination_arn (CloudWatch log group ARN for SMB audit logs), and an optional cache_attributes block with cache_stale_timeout_in_seconds. Requires gateway_type FILE_FSX_SMB. Defaults to {}."
  default     = {}
}

###########################
# CloudWatch Log Group
###########################

variable "create_cloudwatch_log_group" {
  type        = bool
  description = "(Optional) Determines whether this module creates a CloudWatch log group (via the cloudwatch/log_group child module) for gateway health logs and wires it to the gateway. Ignored when cloudwatch_log_group_arn is supplied. Defaults to true."
  default     = true
}

variable "cloudwatch_name_prefix" {
  type        = string
  description = "(Optional) Name prefix for the CloudWatch log group created for gateway health logs. Defaults to /aws/storagegateway/."
  default     = "/aws/storagegateway/"
}

variable "cloudwatch_retention_in_days" {
  type        = number
  description = "(Optional) Number of days to retain gateway log events in the CloudWatch log group. Set to 0 to retain indefinitely. Defaults to 90."
  default     = 90
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_retention_in_days)
    error_message = "The value of cloudwatch_retention_in_days must be one of the valid CloudWatch log retention periods: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}

###########################
# KMS Encryption Key
###########################

variable "create_kms_key" {
  type        = bool
  description = "(Optional) Determines whether this module creates a dedicated KMS key (via the kms child module) to encrypt the CloudWatch log group. Used only when create_cloudwatch_log_group is true. Set to false to supply your own key via kms_key_id. Defaults to true."
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "(Optional) ARN of an existing KMS key used to encrypt the CloudWatch log group. Used only when create_kms_key is false. Defaults to null (the log group is unencrypted by a customer-managed key)."
  default     = null
}

variable "kms_key_description" {
  type        = string
  description = "(Optional) The description applied to the KMS key created by this module."
  default     = "KMS key used to encrypt AWS Storage Gateway CloudWatch logs."
}

variable "kms_key_name_prefix" {
  type        = string
  description = "(Optional) Creates a unique KMS alias beginning with the specified prefix. The alias/ prefix is added automatically if omitted."
  default     = "storage_gateway"
}

variable "kms_key_deletion_window_in_days" {
  type        = number
  description = "(Optional) Duration in days after which the KMS key is deleted after destruction of the resource. Must be between 7 and 30 days. Defaults to 30."
  default     = 30
  validation {
    condition     = var.kms_key_deletion_window_in_days >= 7 && var.kms_key_deletion_window_in_days <= 30
    error_message = "The value of kms_key_deletion_window_in_days must be between 7 and 30 days."
  }
}

variable "kms_key_enable_key_rotation" {
  type        = bool
  description = "(Optional) Specifies whether automatic key rotation is enabled on the KMS key created by this module. Defaults to true."
  default     = true
}
