############################################
# Data Sources
############################################

variable "velocloud_version" {
  description = "(Optional) The version ID of the VeloCloud VCE AMI to use. Defaults to the latest version. Use semantic versioning to specify a version. Example: 4.5"
  default     = "4.5"
  type        = string
}

############################################
# Security Groups
############################################

variable "lan_sg_name" {
  description = "(Optional, Forces new resource) Name of the security group. If omitted, Terraform will assign a random, unique name."
  default     = "velocloud_lan_sg"
  type        = string
}

variable "snmp_mgmt_access_cidr_blocks" {
  description = "(Optional) List of CIDR blocks allowed to SNMP into the VeloCloud instance."
  default     = []
  type        = list(string)
}

variable "ssh_mgmt_access_cidr_blocks" {
  description = "(Optional) List of CIDR blocks allowed to SSH into the VeloCloud instance."
  default     = []
  type        = list(string)
}

variable "wan_mgmt_sg_name" {
  description = "(Optional, Forces new resource) Name of the security group. If omitted, Terraform will assign a random, unique name."
  default     = "velocloud_wan_mgmt_sg"
  type        = string
}

variable "velocloud_lan_cidr_blocks" {
  type        = list(string)
  description = "(Optional) List of CIDR blocks allowed to utilize the VeloCloud instance for SDWAN communication."
  default     = null
}

variable "vpc_id" {
  description = "(Required, Forces new resource) VPC ID. Defaults to the region's default VPC."
  type        = string
}

############################################
# ENI
############################################

variable "mgmt_nic_description" {
  description = "(Optional) Description for the network interface."
  default     = "SDWAN mgmt nic"
  type        = string
}

variable "mgmt_ips" {
  description = "(Optional) List of private IPs to assign to the ENI."
  default     = null
  type        = list(string)
}

variable "public_nic_description" {
  description = "(Optional) Description for the network interface."
  default     = "SDWAN public nic"
  type        = string
}

variable "public_subnet_ids" {
  description = "(Required) Subnet IDs to create the ENI in."
  type        = list(string)
}

variable "public_ips" {
  description = "(Optional) Private IP addresses to associate with the instance in a VPC."
  default     = null
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "(Required) Subnet IDs to create the ENI in."
  type        = list(string)
}

variable "private_nic_description" {
  description = "(Optional) Description for the network interface."
  default     = "SDWAN private nic"
  type        = string
}

variable "private_ips" {
  description = "(Optional) List of private IPs to assign to the ENI."
  default     = null
  type        = list(string)
}

variable "source_dest_check" {
  description = "(Optional) Whether to enable source destination checking for the ENI. Default false."
  default     = false
  type        = bool
}

############################################
# EC2 Instance
############################################

variable "ebs_optimized" {
  description = "(Optional) If true, the launched EC2 instance will be EBS-optimized. Note that if this is not set on an instance type that is optimized by default then this will show as disabled but if the instance type is optimized by default then there is no need to set this and there is no effect to disabling it. See the EBS Optimized section of the AWS User Guide for more information."
  default     = true
  type        = bool
}

variable "monitoring" {
  description = "(Optional) If true, the launched EC2 instance will have detailed monitoring enabled. (Available since v0.6.0)"
  default     = true
  type        = bool
}

variable "instance_type" {
  description = "(Optional) Instance type to use for the instance. Updates to this field will trigger a stop/start of the EC2 instance."
  default     = "c5.xlarge"
  type        = string
}

variable "key_name" {
  description = "(Optional) Key name of the Key Pair to use for the instance; which can be managed using the aws_key_pair resource. Defaults to null."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "(Optional) IAM Instance Profile to launch the instance with. Specified as the name of the Instance Profile. Ensure your credentials have the correct permission to assign the instance profile according to the EC2 documentation, notably iam:PassRole."
  default     = null
  type        = string
}

variable "instance_name_prefix" {
  description = "(Optional) Used to populate the Name tag."
  default     = "aws_prod_sdwan"
  type        = string
}

variable "root_volume_type" {
  description = "(Optional) Type of volume. Valid values include standard, gp2, gp3, io1, io2, sc1, or st1. Defaults to gp3"
  default     = "gp3"
  type        = string
}

variable "root_volume_size" {
  description = "(Optional) Size of the root volume in gibibytes (GiB)."
  default     = 8
  type        = number
}

variable "root_ebs_volume_encrypted" {
  description = "(Optional) Whether to enable volume encryption on the root ebs volume. Defaults to true. Must be configured to perform drift detection."
  default     = true
  type        = bool
}

variable "velocloud_activation_key" {
  description = "(Required) The activation key for the VeloCloud instance(s)."
  type        = string
  validation {
    condition     = can(regex("^[A-Z0-9-]{19}$", var.velocloud_activation_key))
    error_message = "The activation key must be 16 characters long with hyphens every 4 characters and contain only uppercase alphanumeric characters and hyphens. Example (AAA1-2BBB-3C3C-44D4)"
  }
}

variable "velocloud_ignore_cert_errors" {
  description = "(Optional) Whether or not to ignore certificate errors when connecting to the VeloCloud orchestrator. Set to true if using private or self-signed certificates on the orchestrator. Defaults to false."
  default     = false
  type        = bool
}

variable "velocloud_orchestrator" {
  description = "(Required) The IP address or FQDN of the VeloCloud orchestrator. Example: vco.example.com"
  type        = string
}

variable "http_endpoint" {
  type        = string
  description = "(Optional) Whether the metadata service is available. Valid values include enabled or disabled. Defaults to enabled."
  default     = "enabled"
  validation {
    condition     = can(regex("^(enabled|disabled)$", var.http_endpoint))
    error_message = "The value must be either enabled or disabled."
  }
}

variable "http_tokens" {
  type        = string
  description = "(Optional) Whether or not the metadata service requires session tokens, also referred to as Instance Metadata Service Version 2 (IMDSv2). Valid values include optional or required. Defaults to optional."
  default     = "required"
  validation {
    condition     = can(regex("^(optional|required)$", var.http_tokens))
    error_message = "The value must be either optional or required."
  }
}

###############################################################
# General Use Variables
###############################################################

variable "tags" {
  description = "(Optional) Map of tags to assign to the device."
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
    role        = "sdwan"
  }
  type = map(any)
}

variable "number" {
  description = "(Optional) Quantity of resources to make with this module. Example: Setting this to 2 will create 2 of all the required resources. Default: 1"
  default     = 1
  type        = number
}