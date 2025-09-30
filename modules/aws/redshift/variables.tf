###########################
# Required Variables
###########################

variable "cluster_identifier" {
  description = "(Required) The Cluster Identifier. Must be lowercase and contain only alphanumeric characters and hyphens."
  type        = string
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,62}$", var.cluster_identifier))
    error_message = "The cluster_identifier must be lowercase, start with a letter, and contain only alphanumeric characters and hyphens."
  }
}

variable "node_type" {
  description = "(Required) The node type to be provisioned for the cluster. See https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#working-with-clusters-overview for valid node types."
  type        = string
  validation {
    condition = can(regex("^(dc2\\.(large|8xlarge)|ds2\\.(xlarge|8xlarge)|dc1\\.(large|8xlarge)|ra3\\.(xlplus|large|4xlarge|16xlarge))$", var.node_type))
    error_message = "The node_type must be a valid Redshift node type (e.g., ra3.xlplus, ra3.large, ra3.4xlarge, ra3.16xlarge, dc2.large, dc2.8xlarge, ds2.xlarge, ds2.8xlarge, dc1.large, dc1.8xlarge)."
  }
}

###########################
# Database Configuration Variables
###########################

variable "database_name" {
  description = "(Optional) The name of the first database to be created when the cluster is created. If you do not provide a name, Amazon Redshift will create a default database called dev."
  type        = string
  default     = "dev"
  validation {
    condition     = can(regex("^[a-z][a-z0-9_]{0,63}$", var.database_name))
    error_message = "The database_name must be lowercase, start with a letter, and contain only alphanumeric characters and underscores."
  }
}

variable "master_username" {
  description = "(Required unless manage_master_password is true) Username for the master DB user. Must be 1-128 alphanumeric characters, start with a letter."
  type        = string
  default     = null
  validation {
    condition     = var.master_username == null || can(regex("^[a-z][a-z0-9_]{0,127}$", var.master_username))
    error_message = "The master_username must start with a letter and contain only alphanumeric characters and underscores."
  }
}

variable "master_password" {
  description = "(Required unless manage_master_password is true) Password for the master DB user. Must be between 8 and 64 characters. Must contain at least one uppercase letter, one lowercase letter, and one number. Printable ASCII characters except /, @, or \"."
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_password" {
  description = "(Optional) Whether to manage the master password with AWS Secrets Manager. When true, AWS manages the master password."
  type        = bool
  default     = false
}

variable "master_password_secret_kms_key_id" {
  description = "(Optional) The ARN or ID of the KMS key to encrypt the secret containing the master password. Only used when manage_master_password is true."
  type        = string
  default     = null
}

###########################
# Cluster Configuration Variables
###########################

variable "cluster_type" {
  description = "(Optional) The cluster type to use. Either single-node or multi-node."
  type        = string
  default     = "single-node"
  validation {
    condition     = contains(["single-node", "multi-node"], var.cluster_type)
    error_message = "The cluster_type must be either single-node or multi-node."
  }
}

variable "number_of_nodes" {
  description = "(Optional) The number of compute nodes in the cluster. Required when cluster_type is multi-node. Must be at least 2 and at most 128."
  type        = number
  default     = 2
  validation {
    condition     = var.number_of_nodes >= 2 && var.number_of_nodes <= 128
    error_message = "The number_of_nodes must be between 2 and 128 for multi-node clusters."
  }
}

variable "cluster_version" {
  description = "(Optional) The version of the Amazon Redshift engine software that you want to use."
  type        = string
  default     = "1.0"
}

variable "cluster_parameter_group_name" {
  description = "(Optional) The name of the parameter group to be associated with this cluster."
  type        = string
  default     = null
}

variable "cluster_subnet_group_name" {
  description = "(Optional) The name of a cluster subnet group to be associated with this cluster."
  type        = string
  default     = null
}

###########################
# Security Variables
###########################

variable "vpc_security_group_ids" {
  description = "(Optional) A list of Virtual Private Cloud (VPC) security groups to be associated with the cluster."
  type        = list(string)
  default     = []
}

variable "iam_roles" {
  description = "(Optional) A list of IAM Role ARNs to associate with the cluster. A Maximum of 10 can be associated to the cluster at any time."
  type        = list(string)
  default     = []
  validation {
    condition     = length(var.iam_roles) <= 10
    error_message = "A maximum of 10 IAM roles can be associated with the cluster."
  }
}

variable "default_iam_role_arn" {
  description = "(Optional) The Amazon Resource Name (ARN) for the IAM role that was set as default for the cluster when the cluster was created."
  type        = string
  default     = null
}

variable "manage_iam_roles" {
  description = "(Optional) Whether to use the separate aws_redshift_cluster_iam_roles resource to manage IAM roles. If false, IAM roles are managed directly on the cluster resource."
  type        = bool
  default     = false
}

variable "kms_key_id" {
  description = "(Optional) The ARN for the KMS encryption key. When specifying kms_key_id, encrypted needs to be set to true."
  type        = string
  default     = null
}

variable "encrypted" {
  description = "(Optional) Whether the data in the cluster is encrypted at rest."
  type        = bool
  default     = true
}

variable "enhanced_vpc_routing" {
  description = "(Optional) If true, enhanced VPC routing is enabled. Forces all COPY and UNLOAD traffic between the cluster and data repositories to go through your VPC."
  type        = bool
  default     = true
}

###########################
# Networking Variables
###########################

variable "publicly_accessible" {
  description = "(Optional) If true, the cluster can be accessed from a public network. SECURITY WARNING: Set to false for production environments."
  type        = bool
  default     = false
}

variable "elastic_ip" {
  description = "(Optional) The Elastic IP (EIP) address for the cluster. Applicable only for single-node clusters."
  type        = string
  default     = null
}

variable "port" {
  description = "(Optional) The port number on which the cluster accepts incoming connections."
  type        = number
  default     = 5439
  validation {
    condition     = var.port >= 1150 && var.port <= 65535
    error_message = "The port must be between 1150 and 65535."
  }
}

variable "availability_zone" {
  description = "(Optional) The EC2 Availability Zone (AZ) in which you want Amazon Redshift to provision the cluster."
  type        = string
  default     = null
}

variable "availability_zone_relocation_enabled" {
  description = "(Optional) If true, the cluster can be relocated to another availability zone, either automatically by AWS or when requested."
  type        = bool
  default     = false
}

variable "multi_az" {
  description = "(Optional) If true, the cluster will be created in Multi-AZ mode. Applicable for RA3 node types only."
  type        = bool
  default     = false
}

###########################
# Maintenance and Snapshot Variables
###########################

variable "preferred_maintenance_window" {
  description = "(Optional) The weekly time range during which system maintenance can occur, in UTC. Format: ddd:hh24:mi-ddd:hh24:mi."
  type        = string
  default     = "sun:05:00-sun:06:00"
  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):[0-2][0-9]:[0-5][0-9]$", var.preferred_maintenance_window))
    error_message = "The preferred_maintenance_window must be in the format ddd:hh24:mi-ddd:hh24:mi."
  }
}

variable "automated_snapshot_retention_period" {
  description = "(Optional) The number of days that automated snapshots are retained. Set to 0 to disable automated snapshots."
  type        = number
  default     = 7
  validation {
    condition     = var.automated_snapshot_retention_period >= 0 && var.automated_snapshot_retention_period <= 35
    error_message = "The automated_snapshot_retention_period must be between 0 and 35 days."
  }
}

variable "manual_snapshot_retention_period" {
  description = "(Optional) The number of days to retain manual snapshots. Set to -1 for indefinite retention."
  type        = number
  default     = -1
  validation {
    condition     = var.manual_snapshot_retention_period == -1 || (var.manual_snapshot_retention_period >= 1 && var.manual_snapshot_retention_period <= 3653)
    error_message = "The manual_snapshot_retention_period must be -1 (indefinite) or between 1 and 3653 days."
  }
}

variable "final_snapshot_identifier" {
  description = "(Optional) The identifier of the final snapshot that is created before deleting the cluster. Required if skip_final_snapshot is false."
  type        = string
  default     = null
}

variable "skip_final_snapshot" {
  description = "(Optional) Determines whether a final snapshot is created before the cluster is deleted."
  type        = bool
  default     = false
}

variable "snapshot_cluster_identifier" {
  description = "(Optional) The name of the cluster the source snapshot was created from."
  type        = string
  default     = null
}

variable "snapshot_identifier" {
  description = "(Optional) The name of the snapshot from which to create the new cluster."
  type        = string
  default     = null
}

variable "snapshot_copy_destination_region" {
  description = "(Optional) The destination region that you want to copy snapshots to."
  type        = string
  default     = null
}

variable "snapshot_copy_retention_period" {
  description = "(Optional) The number of days to retain newly copied snapshots in the destination region. Must be between 1 and 35 days."
  type        = number
  default     = null
}


variable "snapshot_copy_grant_name" {
  description = "(Optional) The name of the snapshot copy grant to use when snapshots of an encrypted cluster are copied to the destination region."
  type        = string
  default     = null
}

variable "allow_version_upgrade" {
  description = "(Optional) If true, major version upgrades can be applied during the maintenance window to the Amazon Redshift engine."
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "(Optional) Specifies whether any cluster modifications are applied immediately, or during the next maintenance window."
  type        = bool
  default     = false
}

###########################
# Logging Variables
###########################

variable "logging_bucket_name" {
  description = "(Optional) The name of an existing S3 bucket where the log files are to be stored. Must be in the same region as the cluster."
  type        = string
  default     = null
}

variable "logging_s3_key_prefix" {
  description = "(Optional) The prefix applied to the log file names."
  type        = string
  default     = null
}

variable "log_destination_type" {
  description = "(Optional) The log destination type. Valid values are s3 and cloudwatch."
  type        = string
  default     = "s3"
  validation {
    condition     = contains(["s3", "cloudwatch"], var.log_destination_type)
    error_message = "The log_destination_type must be either s3 or cloudwatch."
  }
}

variable "log_exports" {
  description = "(Optional) The collection of exported log types. Valid values are connectionlog, useractivitylog, and userlog."
  type        = list(string)
  default     = []
  validation {
    condition = alltrue([
      for log_type in var.log_exports : contains(["connectionlog", "useractivitylog", "userlog"], log_type)
    ])
    error_message = "All log_exports values must be one of: connectionlog, useractivitylog, userlog."
  }
}

###########################
# Advanced Configuration Variables
###########################

variable "aqua_configuration_status" {
  description = "(Optional) The value represents how the cluster is configured to use AQUA. Valid values are enabled, disabled, and auto."
  type        = string
  default     = "auto"
  validation {
    condition     = contains(["enabled", "disabled", "auto"], var.aqua_configuration_status)
    error_message = "The aqua_configuration_status must be one of: enabled, disabled, auto."
  }
}

variable "maintenance_track_name" {
  description = "(Optional) The name of the maintenance track for the restored cluster."
  type        = string
  default     = "current"
}

###########################
# Subnet Group Variables
###########################

variable "create_subnet_group" {
  description = "(Optional) Whether to create a new subnet group for the cluster."
  type        = bool
  default     = false
}

variable "subnet_group_name" {
  description = "(Optional) The name of the subnet group. Required if create_subnet_group is true."
  type        = string
  default     = null
}

variable "subnet_group_description" {
  description = "(Optional) The description for the subnet group."
  type        = string
  default     = "Redshift cluster subnet group"
}

variable "subnet_ids" {
  description = "(Optional) A list of VPC subnet IDs. Required if create_subnet_group is true."
  type        = list(string)
  default     = []
}

###########################
# Parameter Group Variables
###########################

variable "create_parameter_group" {
  description = "(Optional) Whether to create a new parameter group for the cluster."
  type        = bool
  default     = false
}

variable "parameter_group_name" {
  description = "(Optional) The name of the Redshift parameter group. Required if create_parameter_group is true."
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "(Optional) The family of the Redshift parameter group. Required if create_parameter_group is true."
  type        = string
  default     = "redshift-1.0"
  validation {
    condition     = can(regex("^redshift-[0-9]\\.[0-9]$", var.parameter_group_family))
    error_message = "The parameter_group_family must be in the format redshift-X.X (e.g., redshift-1.0)."
  }
}

variable "parameter_group_description" {
  description = "(Optional) The description for the parameter group."
  type        = string
  default     = "Redshift cluster parameter group"
}

variable "parameters" {
  description = "(Optional) A list of parameter objects to apply to the parameter group."
  type = list(object({
    name  = string
    value = string
  }))
  default = []
}

###########################
# Snapshot Schedule Variables
###########################

variable "create_snapshot_schedule" {
  description = "(Optional) Whether to create a snapshot schedule for the cluster."
  type        = bool
  default     = false
}

variable "snapshot_schedule_identifier" {
  description = "(Optional) The identifier for the snapshot schedule. Required if create_snapshot_schedule is true."
  type        = string
  default     = null
}

variable "snapshot_schedule_description" {
  description = "(Optional) The description for the snapshot schedule."
  type        = string
  default     = "Redshift cluster snapshot schedule"
}

variable "snapshot_schedule_definitions" {
  description = "(Optional) The definition of the snapshot schedule. The definition is made up of schedule expressions (e.g., 'rate(12 hours)' or 'cron(0 12 * * ? *)')."
  type        = list(string)
  default     = []
}

###########################
# Usage Limit Variables
###########################

variable "usage_limits" {
  description = "(Optional) A map of usage limit configurations. The key is a unique identifier for the limit."
  type = map(object({
    feature_type  = string           # The feature type for the limit. Valid values are spectrum, concurrency-scaling, or cross-region-datasharing.
    limit_type    = string           # The type of limit. Valid values are time or data-scanned.
    amount        = number           # The limit amount.
    breach_action = optional(string) # The action when the limit is breached. Valid values are log, emit-metric, and disable.
    period        = optional(string) # The time period for the limit. Valid values are daily, weekly, and monthly.
  }))
  default = {}
  validation {
    condition = alltrue([
      for k, v in var.usage_limits : contains(["spectrum", "concurrency-scaling", "cross-region-datasharing"], v.feature_type)
    ])
    error_message = "All usage_limits feature_type values must be one of: spectrum, concurrency-scaling, cross-region-datasharing."
  }
  validation {
    condition = alltrue([
      for k, v in var.usage_limits : contains(["time", "data-scanned"], v.limit_type)
    ])
    error_message = "All usage_limits limit_type values must be one of: time, data-scanned."
  }
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) A map of tags to assign to all resources."
  type        = map(any)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}