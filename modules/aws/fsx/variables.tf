###########################
# FSx Windows File System
###########################

variable "active_directory_id" {
  type        = string
  description = "(Optional) The ID for an existing AWS Managed Microsoft Active Directory (Directory Service) instance that the file system should join. Conflicts with self_managed_active_directory. Exactly one Active Directory configuration (this or self_managed_active_directory) must be provided."
  default     = null
}

variable "aliases" {
  type        = list(string)
  description = "(Optional) A list of DNS alias names that you want to associate with the Amazon FSx file system. For more information, see Working with DNS Aliases."
  default     = null
}

variable "automatic_backup_retention_days" {
  type        = number
  description = "(Optional) The number of days to retain automatic backups. Minimum of 0 and maximum of 90. Set to 0 to disable automatic backups. Defaults to 7."
  default     = 7
  validation {
    condition     = var.automatic_backup_retention_days >= 0 && var.automatic_backup_retention_days <= 90
    error_message = "The value of automatic_backup_retention_days must be between 0 and 90."
  }
}

variable "backup_id" {
  type        = string
  description = "(Optional) The ID of the source backup to create the file system from."
  default     = null
}

variable "copy_tags_to_backups" {
  type        = bool
  description = "(Optional) A boolean flag indicating whether tags on the file system should be copied to backups. Defaults to true."
  default     = true
}

variable "daily_automatic_backup_start_time" {
  type        = string
  description = "(Optional) The preferred time (in HH:MM format) to take daily automatic backups, in the UTC time zone. Defaults to 23:59."
  default     = "23:59"
}

variable "deployment_type" {
  type        = string
  description = "(Optional) Specifies the file system deployment type. Valid values are MULTI_AZ_1, SINGLE_AZ_1, and SINGLE_AZ_2. Defaults to SINGLE_AZ_1."
  default     = "SINGLE_AZ_1"
  validation {
    condition     = contains(["MULTI_AZ_1", "SINGLE_AZ_1", "SINGLE_AZ_2"], var.deployment_type)
    error_message = "The value of deployment_type must be one of MULTI_AZ_1, SINGLE_AZ_1, or SINGLE_AZ_2."
  }
}

variable "name" {
  type        = string
  description = "(Required) The value of the Name tag applied to the file system and used as a friendly identifier."
}

variable "preferred_subnet_id" {
  type        = string
  description = "(Optional) Specifies the subnet in which you want the preferred file server to be located. Required when deployment_type is MULTI_AZ_1."
  default     = null
}

variable "security_group_ids" {
  type        = list(string)
  description = "(Optional) A list of IDs for the security groups that apply to the specified network interfaces created for file system access. These security groups apply to all network interfaces."
  default     = null
}

variable "skip_final_backup" {
  type        = bool
  description = "(Optional) When enabled, will skip the default final backup taken when the file system is deleted. Defaults to false."
  default     = false
}

variable "storage_capacity" {
  type        = number
  description = "(Optional) Storage capacity (GiB) of the file system. Minimum of 32 and maximum of 65536. If the storage type is set to HDD the minimum value is 2000. Required when not creating the file system from a backup. Defaults to 32."
  default     = 32
  validation {
    condition     = var.storage_capacity >= 32 && var.storage_capacity <= 65536
    error_message = "The value of storage_capacity must be between 32 and 65536 GiB."
  }
}

variable "storage_type" {
  type        = string
  description = "(Optional) Specifies the storage type. Valid values are SSD and HDD. HDD is supported on SINGLE_AZ_2 and MULTI_AZ_1 deployment types. Defaults to SSD."
  default     = "SSD"
  validation {
    condition     = contains(["SSD", "HDD"], var.storage_type)
    error_message = "The value of storage_type must be either SSD or HDD."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "(Required) A list of IDs for the subnets that the file system will be accessible from. For SINGLE_AZ deployments provide a single subnet; for MULTI_AZ_1 provide two subnets and set preferred_subnet_id."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources created by this module."
  default     = {}
}

variable "throughput_capacity" {
  type        = number
  description = "(Optional) Throughput (megabytes per second) of the file system in power of 2 increments. Minimum of 8 and maximum of 2048. Defaults to 32."
  default     = 32
  validation {
    condition     = var.throughput_capacity >= 8 && var.throughput_capacity <= 2048
    error_message = "The value of throughput_capacity must be between 8 and 2048 MB/s."
  }
}

variable "weekly_maintenance_start_time" {
  type        = string
  description = "(Optional) The preferred start time (in d:HH:MM format) to perform weekly maintenance, in the UTC time zone. Defaults to 1:01:00."
  default     = "1:01:00"
}

###########################
# Self Managed AD Config
###########################

variable "self_managed_active_directory" {
  type = object({
    dns_ips                                = list(string)
    domain_name                            = string
    password                               = string
    username                               = string
    file_system_administrators_group       = optional(string, "Domain Admins")
    organizational_unit_distinguished_name = optional(string)
  })
  description = "(Optional) Configuration block for joining the file system to a self-managed Active Directory. Conflicts with active_directory_id. dns_ips is a list of up to two DNS server/domain controller IPs; domain_name is the fully qualified domain name; username/password are the service account credentials FSx uses to join the domain; file_system_administrators_group defaults to Domain Admins; organizational_unit_distinguished_name is the OU the file system joins (e.g. OU=FSx,DC=example,DC=com). Note: the password is persisted in Terraform state in plaintext — supply it from a secret store and protect state access accordingly."
  default     = null
}

###########################
# KMS Encryption Key
###########################

variable "create_kms_key" {
  type        = bool
  description = "(Optional) Determines whether this module creates a dedicated KMS key (via the kms child module) to encrypt the file system and audit logs. Set to false to supply your own key via kms_key_id. Defaults to true."
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "(Optional) ARN of an existing KMS key used to encrypt the file system and audit logs. Used only when create_kms_key is false."
  default     = null
}

variable "kms_key_description" {
  type        = string
  description = "(Optional) The description applied to the KMS key created by this module."
  default     = "KMS key used to encrypt Amazon FSx for Windows File Server data at rest and its audit logs."
}

variable "kms_key_name_prefix" {
  type        = string
  description = "(Optional) Creates a unique KMS alias beginning with the specified prefix. The alias/ prefix is added automatically if omitted."
  default     = "fsx_windows"
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

###########################
# Audit Log Configuration
###########################

variable "enable_audit_logs" {
  type        = bool
  description = "(Optional) Determines whether a CloudWatch log group is created and file/file-share access auditing is enabled on the file system. Defaults to true."
  default     = true
}

variable "file_access_audit_log_level" {
  type        = string
  description = "(Optional) Sets which attempt type is logged by Amazon FSx for file and folder accesses. Valid values are SUCCESS_ONLY, FAILURE_ONLY, SUCCESS_AND_FAILURE, and DISABLED. Defaults to SUCCESS_AND_FAILURE."
  default     = "SUCCESS_AND_FAILURE"
  validation {
    condition     = contains(["SUCCESS_ONLY", "FAILURE_ONLY", "SUCCESS_AND_FAILURE", "DISABLED"], var.file_access_audit_log_level)
    error_message = "The value of file_access_audit_log_level must be one of SUCCESS_ONLY, FAILURE_ONLY, SUCCESS_AND_FAILURE, or DISABLED."
  }
}

variable "file_share_access_audit_log_level" {
  type        = string
  description = "(Optional) Sets which attempt type is logged by Amazon FSx for file share accesses. Valid values are SUCCESS_ONLY, FAILURE_ONLY, SUCCESS_AND_FAILURE, and DISABLED. Defaults to SUCCESS_AND_FAILURE."
  default     = "SUCCESS_AND_FAILURE"
  validation {
    condition     = contains(["SUCCESS_ONLY", "FAILURE_ONLY", "SUCCESS_AND_FAILURE", "DISABLED"], var.file_share_access_audit_log_level)
    error_message = "The value of file_share_access_audit_log_level must be one of SUCCESS_ONLY, FAILURE_ONLY, SUCCESS_AND_FAILURE, or DISABLED."
  }
}

variable "cloudwatch_name_prefix" {
  type        = string
  description = "(Optional) Name prefix for the CloudWatch log group that receives FSx audit logs. FSx requires the prefix to begin with /aws/fsx/. Defaults to /aws/fsx/windows_audit_."
  default     = "/aws/fsx/windows_audit_"
}

variable "cloudwatch_retention_in_days" {
  type        = number
  description = "(Optional) Number of days to retain audit log events in the CloudWatch log group. Set to 0 to retain indefinitely. Defaults to 90."
  default     = 90
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, 3653], var.cloudwatch_retention_in_days)
    error_message = "The value of cloudwatch_retention_in_days must be one of the valid CloudWatch log retention periods: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, 3653."
  }
}
