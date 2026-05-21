###########################
# Data Source Variables
###########################

variable "ami_id" {
  description = "(Optional) AMI ID to override the Zscaler Marketplace AMI. If not specified, the latest Zscaler App Connector AMI is selected automatically via the AWS Marketplace product code."
  type        = string
  default     = null
  validation {
    condition     = var.ami_id == null || can(regex("^ami-", var.ami_id))
    error_message = "ami_id must be null or a valid AMI ID beginning with 'ami-'."
  }
}

###########################
# Security Group Variables
###########################

variable "sg_name" {
  description = "(Optional) Name for the ZPA App Connector security group."
  type        = string
  default     = "zpa_connector_sg"
}

variable "vpc_id" {
  description = "(Required, Forces new resource) VPC ID in which to create the ZPA App Connector instances and security group."
  type        = string
}

###########################
# EC2 Instance Variables
###########################

variable "encrypted" {
  description = "(Optional) Whether to encrypt the root EBS volume. Defaults to true."
  type        = bool
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.encrypted))
    error_message = "encrypted must be either true or false."
  }
}

variable "http_endpoint" {
  description = "(Optional) Whether the instance metadata service is available. Valid values: enabled, disabled. Defaults to enabled."
  type        = string
  default     = "enabled"
  validation {
    condition     = can(regex("^(enabled|disabled)$", var.http_endpoint))
    error_message = "http_endpoint must be either enabled or disabled."
  }
}

variable "http_tokens" {
  description = "(Optional) Whether IMDSv2 session tokens are required. Valid values: optional, required. Defaults to required."
  type        = string
  default     = "required"
  validation {
    condition     = can(regex("^(optional|required)$", var.http_tokens))
    error_message = "http_tokens must be either optional or required."
  }
}

variable "iam_instance_profile" {
  description = "(Optional) IAM instance profile name to attach to the ZPA App Connector instances for SSM access."
  type        = string
  default     = null
}

variable "instance_name_prefix" {
  description = "(Optional) Prefix used to generate the Name tag for each connector instance. A zero-padded two-digit index is appended (e.g., 'ZPAVP' → 'ZPAVP01', 'ZPAVP02', 'ZPAVP03')."
  type        = string
  default     = "ZPAVP"
}

variable "instance_type" {
  description = "(Optional) EC2 instance type for ZPA App Connector instances. Defaults to m5a.xlarge per Zscaler's official module recommendation."
  type        = string
  default     = "m7i.large"
}

variable "key_name" {
  description = "(Optional) EC2 Key Pair name to associate with the instances for emergency console access. SSM access is preferred."
  type        = string
  default     = null
}

variable "monitoring" {
  description = "(Optional) Enable detailed CloudWatch monitoring on the instances. Defaults to true."
  type        = bool
  default     = true
}

variable "private_ips" {
  description = "(Optional) List of static private IP addresses to assign to each connector, one per subnet. Must be provided in the same order as subnet_ids. If null, AWS assigns IPs automatically."
  type        = list(string)
  default     = null
}

variable "provisioning_key" {
  description = "(Required) ZPA App Connector provisioning key from the ZPA admin portal. This key registers the connectors to a specific App Connector Group. Mark as sensitive in the calling workspace. Connectors will NOT carry production traffic until Application Segments are assigned to the group in the ZPA admin portal."
  type        = string
  sensitive   = true
}

variable "root_delete_on_termination" {
  description = "(Optional) Whether to delete the root EBS volume when the instance is terminated. Defaults to true."
  type        = bool
  default     = true
  validation {
    condition     = can(regex("^(true|false)$", var.root_delete_on_termination))
    error_message = "root_delete_on_termination must be either true or false."
  }
}

variable "root_volume_size" {
  description = "(Optional) Root EBS volume size in GiB. Minimum 64 GiB required by the Zscaler Marketplace AMI snapshot."
  type        = number
  default     = 75
}

variable "root_volume_type" {
  description = "(Optional) Root EBS volume type. Valid values: standard, gp2, gp3, io1, io2, sc1, st1. Defaults to gp3."
  type        = string
  default     = "gp3"
  validation {
    condition     = can(regex("^(standard|gp2|gp3|io1|io2|sc1|st1)$", var.root_volume_type))
    error_message = "root_volume_type must be one of: standard, gp2, gp3, io1, io2, sc1, st1."
  }
}

variable "subnet_ids" {
  description = "(Required) List of private subnet IDs in which to launch one connector per subnet. The number of subnets determines the number of connector instances created."
  type        = list(string)
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to all resources created by this module."
  type        = map(any)
  default = {
    created_by  = "terraform"
    environment = "prod"
    role        = "zpa_connector"
    terraform   = "true"
  }
}
