###########################
# FSx ONTAP File System
###########################

variable "automatic_backup_retention_days" {
  type        = number
  description = "(Optional) The number of days to retain automatic backups. Minimum of 0 and maximum of 90. Set to 0 to disable automatic backups. Defaults to 7."
  default     = 7
  validation {
    condition     = var.automatic_backup_retention_days >= 0 && var.automatic_backup_retention_days <= 90
    error_message = "The value of automatic_backup_retention_days must be between 0 and 90."
  }
}

variable "daily_automatic_backup_start_time" {
  type        = string
  description = "(Optional) The preferred time (in HH:MM format) to take daily automatic backups, in the UTC time zone. Requires automatic_backup_retention_days to be greater than 0. Defaults to 23:59."
  default     = "23:59"
}

variable "deployment_type" {
  type        = string
  description = "(Optional) The file system deployment type. Valid values are SINGLE_AZ_1, SINGLE_AZ_2, MULTI_AZ_1, and MULTI_AZ_2. Defaults to MULTI_AZ_1."
  default     = "MULTI_AZ_1"
  validation {
    condition     = contains(["SINGLE_AZ_1", "SINGLE_AZ_2", "MULTI_AZ_1", "MULTI_AZ_2"], var.deployment_type)
    error_message = "The value of deployment_type must be one of SINGLE_AZ_1, SINGLE_AZ_2, MULTI_AZ_1, or MULTI_AZ_2."
  }
}

variable "disk_iops_configuration" {
  type = object({
    iops = optional(number)
    mode = optional(string, "AUTOMATIC")
  })
  description = "(Optional) The SSD IOPS configuration for the file system. mode is AUTOMATIC (provisions 3 IOPS per GB) or USER_PROVISIONED; iops sets the total provisioned IOPS when mode is USER_PROVISIONED. Defaults to null, which lets the provider apply AUTOMATIC."
  default     = null
  validation {
    condition     = var.disk_iops_configuration == null ? true : contains(["AUTOMATIC", "USER_PROVISIONED"], var.disk_iops_configuration.mode)
    error_message = "The value of disk_iops_configuration.mode must be either AUTOMATIC or USER_PROVISIONED."
  }
}

variable "endpoint_ip_address_range" {
  type        = string
  description = "(Optional) The IP address range in which the endpoints to access the file system are created. Only supported on MULTI_AZ deployment types; must be outside the VPC CIDR. Defaults to null."
  default     = null
}

variable "fsx_admin_password" {
  type        = string
  description = "(Optional) The ONTAP administrative password for the fsxadmin user used to administer the file system via the ONTAP CLI/REST API. Stored in Terraform state in plaintext; supply from a secret store. Defaults to null."
  default     = null
}

variable "ha_pairs" {
  type        = number
  description = "(Optional) The number of high-availability (HA) pairs for the file system. Valid values are 1 through 12. Only Gen 2 SINGLE_AZ deployments support more than 1. Defaults to null, which lets the provider apply its default of 1."
  default     = null
}

variable "name" {
  type        = string
  description = "(Required) The value of the Name tag applied to the file system and used as a friendly identifier."
}

variable "preferred_subnet_id" {
  type        = string
  description = "(Optional) The subnet in which the preferred file server is located. Required for MULTI_AZ deployment types. Defaults to null."
  default     = null
}

variable "route_table_ids" {
  type        = list(string)
  description = "(Optional) A list of route table IDs that are associated with the file system. Used by MULTI_AZ deployments so traffic to the floating endpoint IPs is routed correctly. Defaults to null."
  default     = null
}

variable "security_group_ids" {
  type        = list(string)
  description = "(Optional) A list of IDs for the security groups that apply to the network interfaces created for file system access. Defaults to null."
  default     = null
}

variable "storage_capacity" {
  type        = number
  description = "(Required) The storage capacity (GiB) of the file system. Valid values are between 1024 and 1048576 GiB."
  validation {
    condition     = var.storage_capacity >= 1024 && var.storage_capacity <= 1048576
    error_message = "The value of storage_capacity must be between 1024 and 1048576 GiB."
  }
}

variable "storage_type" {
  type        = string
  description = "(Optional) The storage type of the file system. The only valid value for FSx for NetApp ONTAP is SSD. Defaults to SSD."
  default     = "SSD"
  validation {
    condition     = contains(["SSD"], var.storage_type)
    error_message = "The value of storage_type must be SSD for FSx for NetApp ONTAP."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "(Required) A list of subnet IDs the file system will be accessible from. Provide one subnet for SINGLE_AZ deployments and two for MULTI_AZ deployments (with preferred_subnet_id set)."
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resources created by this module."
  default     = {}
}

variable "throughput_capacity" {
  type        = number
  description = "(Optional) The sustained throughput (MB/s) of the file system. Valid values depend on deployment type (e.g. 128, 256, 512, 1024, 2048, 4096). Conflicts with throughput_capacity_per_ha_pair; set exactly one. Defaults to null."
  default     = null
}

variable "throughput_capacity_per_ha_pair" {
  type        = number
  description = "(Optional) The sustained throughput (MB/s) per HA pair. Required for Gen 2 deployment types and when ha_pairs is greater than 1. Conflicts with throughput_capacity; set exactly one. Defaults to null."
  default     = null
}

variable "weekly_maintenance_start_time" {
  type        = string
  description = "(Optional) The preferred start time (in d:HH:MM format) to perform weekly maintenance, in the UTC time zone. Defaults to 1:01:00."
  default     = "1:01:00"
}

###########################
# Storage Virtual Machines
###########################

variable "storage_virtual_machines" {
  type = map(object({
    name                       = optional(string)
    root_volume_security_style = optional(string, "NTFS")
    svm_admin_password         = optional(string)
    active_directory_configuration = optional(object({
      netbios_name = string
      self_managed_active_directory_configuration = object({
        dns_ips                                = list(string)
        domain_name                            = string
        password                               = string
        username                               = string
        file_system_administrators_group       = optional(string)
        organizational_unit_distinguished_name = optional(string)
      })
    }))
  }))
  description = "(Optional) Map of Storage Virtual Machines (SVMs) to create on the file system, keyed by a logical name. Per SVM: name (defaults to the map key), root_volume_security_style (UNIX, NTFS, or MIXED — defaults to NTFS for SMB workloads), svm_admin_password (vsadmin password; stored in state in plaintext), and an optional active_directory_configuration for SMB access (netbios_name plus a self-managed AD config block with dns_ips, domain_name, username, password, and optional file_system_administrators_group and organizational_unit_distinguished_name). Defaults to {}."
  default     = {}
  validation {
    condition     = alltrue([for svm in values(var.storage_virtual_machines) : contains(["UNIX", "NTFS", "MIXED"], svm.root_volume_security_style)])
    error_message = "Each storage_virtual_machines root_volume_security_style must be one of UNIX, NTFS, or MIXED."
  }
}

###########################
# Volumes
###########################

variable "volumes" {
  type = map(object({
    name                                 = optional(string)
    storage_virtual_machine_key          = string
    junction_path                        = optional(string)
    size_in_megabytes                    = number
    security_style                       = optional(string, "NTFS")
    snapshot_policy                      = optional(string)
    storage_efficiency_enabled           = optional(bool, true)
    ontap_volume_type                    = optional(string, "RW")
    skip_final_backup                    = optional(bool, false)
    copy_tags_to_backups                 = optional(bool, false)
    bypass_snaplock_enterprise_retention = optional(bool, false)
    tiering_policy = optional(object({
      name           = string
      cooling_period = optional(number)
    }))
  }))
  description = "(Optional) Map of ONTAP volumes to create, keyed by a logical name. Per volume: name (defaults to the map key), storage_virtual_machine_key (the key of the SVM in storage_virtual_machines this volume belongs to), junction_path (SMB/NFS mount path, e.g. /sales), size_in_megabytes, security_style (UNIX, NTFS, or MIXED — defaults to NTFS), snapshot_policy, storage_efficiency_enabled (dedup/compression, defaults to true), ontap_volume_type (RW or DP, defaults to RW), and an optional tiering_policy block (name one of SNAPSHOT_ONLY, AUTO, ALL, NONE; cooling_period in days). Defaults to {}."
  default     = {}
  validation {
    condition     = alltrue([for vol in values(var.volumes) : contains(["UNIX", "NTFS", "MIXED"], vol.security_style)])
    error_message = "Each volumes security_style must be one of UNIX, NTFS, or MIXED."
  }
  validation {
    condition     = alltrue([for vol in values(var.volumes) : contains(["RW", "DP"], vol.ontap_volume_type)])
    error_message = "Each volumes ontap_volume_type must be one of RW or DP."
  }
  validation {
    condition     = alltrue([for vol in values(var.volumes) : vol.tiering_policy == null ? true : contains(["SNAPSHOT_ONLY", "AUTO", "ALL", "NONE"], vol.tiering_policy.name)])
    error_message = "Each volumes tiering_policy name must be one of SNAPSHOT_ONLY, AUTO, ALL, or NONE."
  }
}

###########################
# KMS Encryption Key
###########################

variable "create_kms_key" {
  type        = bool
  description = "(Optional) Determines whether this module creates a dedicated KMS key (via the kms child module) to encrypt the file system. Set to false to supply your own key via kms_key_id. Defaults to true."
  default     = true
}

variable "kms_key_id" {
  type        = string
  description = "(Optional) ARN of an existing KMS key used to encrypt the file system. Used only when create_kms_key is false."
  default     = null
}

variable "kms_key_description" {
  type        = string
  description = "(Optional) The description applied to the KMS key created by this module."
  default     = "KMS key used to encrypt Amazon FSx for NetApp ONTAP data at rest."
}

variable "kms_key_name_prefix" {
  type        = string
  description = "(Optional) Creates a unique KMS alias beginning with the specified prefix. The alias/ prefix is added automatically if omitted."
  default     = "fsx_ontap"
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
