###########################
# FSx Instance
###########################

variable "storage_capacity" {
  type        = number
  description = "(Optional) Storage capacity (GiB) of the file system. Minimum of 32 and maximum of 65536. If the storage type is set to HDD the minimum value is 2000. Required when not creating filesystem for a backup."
  default     = 2000
}

variable "subnet_ids" {
  type        = list(any)
  description = "(Required) A list of IDs for the subnets that the file system will be accessible from. To specify more than a single subnet set deployment_type to MULTI_AZ_1."
}

variable "throughput_capacity" {
  type        = number
  description = "(Required) Throughput (megabytes per second) of the file system in power of 2 increments. Minimum of 8 and maximum of 2048."
  default     = 64
}

variable "backup_id" {
  type        = string
  description = "(Optional) The ID of the source backup to create the filesystem from."
  default     = ""
}

variable "aliases" {
  description = "(Optional) An array DNS alias names that you want to associate with the Amazon FSx file system. For more information, see Working with DNS Aliases."
}

variable "automatic_backup_retention_days" {
  type        = number
  description = "(Optional) The number of days to retain automatic backups. Minimum of 0 and maximum of 90. Defaults to 7. Set to 0 to disable."
  default     = 7
}

variable "copy_tags_to_backups" {
  type        = bool
  description = "(Optional) A boolean flag indicating whether tags on the file system should be copied to backups. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.copy_tags_to_backups))
    error_message = "The value of copy_tags_to_backups must be either true or false."
  }
}

variable "daily_automatic_backup_start_time" {
  type        = string
  description = "(Optional) The preferred time (in HH:MM format) to take daily automatic backups, in the UTC time zone."
  default     = "23:59"
}

#replace with an sg module in code
variable "security_group_ids" {
  type        = list(any)
  description = "(Optional) A list of IDs for the security groups that apply to the specified network interfaces created for file system access. These security groups will apply to all network interfaces."
}

variable "skip_final_backup" {
  type        = bool
  description = "(Optional) When enabled, will skip the default final backup taken when the file system is deleted. This configuration must be applied separately before attempting to delete the resource to have the desired behavior. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("^(true|false)$", var.skip_final_backup))
    error_message = "The value of skip_final_backup must be either true or false."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the object."
  default = {
    terraform   = "true"
    created_by  = "<YOUR_NAME>"
    environment = "prod"
  }
}

variable "weekly_maintenance_start_time" {
  type        = string
  description = "(Optional) The preferred start time (in d:HH:MM format) to perform weekly maintenance, in the UTC time zone."
  default     = "1:01:00"
}

variable "deployment_type" {
  type        = string
  description = "(Optional) Specifies the file system deployment type, valid values are MULTI_AZ_1, SINGLE_AZ_1 and SINGLE_AZ_2. Default value is SINGLE_AZ_1."
  default     = "SINGLE_AZ_1"
}

variable "preferred_subnet_id" {
  type        = string
  description = "(Optional) Specifies the subnet in which you want the preferred file server to be located. Required for when deployment type is MULTI_AZ_1."
  default     = ""
}

variable "storage_type" {
  type        = string
  description = "(Optional) Specifies the storage type, Valid values are SSD and HDD. HDD is supported on SINGLE_AZ_2 and MULTI_AZ_1 Windows file system deployment types. Default value is SSD."
  default     = "SSD"
}

###########################
# Self Managed AD Config
###########################

variable "dns_ips" {
  type        = list(string)
  description = "(Required) A list of up to two IP addresses of DNS servers or domain controllers in the self-managed AD directory. The IP addresses need to be either in the same VPC CIDR range as the file system or in the private IP version 4 (IPv4) address ranges as specified in RFC 1918."
  default     = ["10.11.1.100", "10.11.2.100"]
}

variable "domain_name" {
  type        = string
  description = "(Required) The fully qualified domain name of the self-managed AD directory. For example, corp.example.com."
}

variable "password" {
  type        = string
  description = "(Required) The password for the service account on your self-managed AD domain that Amazon FSx will use to join to your AD domain."
}

variable "username" {
  type        = string
  description = "(Required) The user name for the service account on your self-managed AD domain that Amazon FSx will use to join to your AD domain."
}

variable "file_system_administrators_group" {
  type        = string
  description = "(Optional) The name of the domain group whose members are granted administrative privileges for the file system. Administrative privileges include taking ownership of files and folders, and setting audit controls (audit ACLs) on files and folders. The group that you specify must already exist in your domain. Defaults to Domain Admins."
  default     = "Domain Admins"
}

variable "organizational_unit_distinguished_name" {
  type        = string
  description = "(Optional) The fully qualified distinguished name of the organizational unit within your self-managed AD directory that the Windows File Server instance will join. For example, OU=FSx,DC=yourdomain,DC=corp,DC=com. Only accepts OU as the direct parent of the file system. If none is provided, the FSx file system is created in the default location of your self-managed AD directory. To learn more, see RFC 2253."
}

###########################
# KMS Key
###########################

variable "fsx_key_description" {
  type        = string
  description = "(Optional) The description of the key as viewed in AWS console."
  default     = "fsx kms key used to encrypt fsx data at rest"
}

variable "fsx_key_name" {
  type        = string
  description = "Name of the fsx KMS key"
  default     = "alias/fsx_kms_key"
}

variable "fsx_cloudwatch_key_name" {
  type        = string
  description = "Name of the cloudwatch for fsx KMS key"
  default     = "alias/fsx_cloudwatch_kms_key"
}

variable "fsx_cloudwatch_key_description" {
  type        = string
  description = "(Optional) The description of the key as viewed in AWS console."
  default     = "CloudWatch kms key used to encrypt fsx logs"
}

variable "deletion_window_in_days" {
  type        = number
  description = "(Optional) Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 30 days."
  default     = 30
}

variable "enable_key_rotation" {
  type        = bool
  description = "(Optional) Specifies whether key rotation is enabled. Defaults to false."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.enable_key_rotation))
    error_message = "The value of enable_key_rotation must be either true or false."
  }
}

variable "key_usage" {
  type        = string
  description = "(Optional) Specifies the intended use of the key. Defaults to ENCRYPT_DECRYPT, and only symmetric encryption and decryption are supported."
  default     = "ENCRYPT_DECRYPT"
}

variable "is_enabled" {
  type        = string
  description = "(Optional) Specifies whether the key is enabled. Defaults to true."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.is_enabled))
    error_message = "The value of is_enabled must be either true or false."
  }
}

variable "policy" {
  type        = string
  description = "(Optional) A valid policy JSON document. Although this is a key policy, not an IAM policy, an aws_iam_policy_document, in the form that designates a principal, can be used. For more information about building policy documents with Terraform, see the AWS IAM Policy Document Guide."
  default     = ""
}

###########################
# Audit Log Config
###########################

#Global
variable "enable_audit_logs" {
  type        = bool
  description = "Determines count for cloudwatch log group, IAM policy, and IAM role. Defaults to true and enters a count of 1 to create resources."
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.enable_audit_logs))
    error_message = "The value of enable_audit_logs must be either true or false."
  }
}

variable "file_access_audit_log_level" {
  type        = string
  description = "(Optional) Sets which attempt type is logged by Amazon FSx for file and folder accesses. Valid values are SUCCESS_ONLY, FAILURE_ONLY, SUCCESS_AND_FAILURE, and DISABLED. Default value is DISABLED."
  default     = "SUCCESS_AND_FAILURE"
}

variable "file_share_access_audit_log_level" {
  type        = string
  description = "(Optional) Sets which attempt type is logged by Amazon FSx for file share accesses. Valid values are SUCCESS_ONLY, FAILURE_ONLY, SUCCESS_AND_FAILURE, and DISABLED. Default value is DISABLED."
  default     = "SUCCESS_AND_FAILURE"
}

#Cloudwatch Log Group

variable "cloudwatch_name_prefix" {
  type        = string
  description = ""
  default     = "/aws/fsx/fsx_access_logs_"
}

variable "cloudwatch_retention_in_days" {
  type        = number
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default     = 90
}
