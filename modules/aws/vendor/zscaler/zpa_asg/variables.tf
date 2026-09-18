###########################
# Data Source Variables
###########################

variable "ami_id" {
  description = "(Optional) AMI ID override for the ZPA App Connector. When null, the latest Marketplace zpa-connector-el9* AMI is selected."
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
  default     = "zpa_connector_asg_sg"
}

variable "vpc_id" {
  description = "(Required, Forces new resource) VPC ID for the connector security group."
  type        = string
}

###########################
# Launch Template Variables
###########################

variable "name" {
  description = "(Required) Base name for the Auto Scaling group and launch template prefix."
  type        = string
}

variable "instance_name_prefix" {
  description = "(Optional) Name tag applied to instances launched by the ASG."
  type        = string
  default     = "AWSZPAVPR"
}

variable "instance_type" {
  description = "(Optional) EC2 instance type. Defaults to m7i.large. Marketplace RHEL AMIs do not support flex variants."
  type        = string
  default     = "m7i.large"
}

variable "key_name" {
  description = "(Optional) EC2 Key Pair name for emergency console access. SSM is preferred."
  type        = string
  default     = null
}

variable "iam_instance_profile" {
  description = "(Required) IAM instance profile name for SSM and instance permissions (e.g. ssm-role)."
  type        = string
}

variable "associate_public_ip_address" {
  description = "(Optional) Associate a public IP. Defaults to false."
  type        = bool
  default     = false
}

variable "encrypted" {
  description = "(Optional) Encrypt the root EBS volume via launch-template block_device_mappings. Defaults to false: the Zscaler Marketplace AMI is already vendor-pre-encrypted, and Sunward Gen2 production connectors use encrypted=false because AWS has rejected re-encryption on this AMI path. Callers may set true and validate in plan/apply if desired."
  type        = bool
  default     = false
}

variable "root_device_name" {
  description = "(Optional) Root device name for the launch-template block_device_mappings override. Must match the AMI root device or size/type/encryption overrides are silently ignored. zpa-connector-el9* uses /dev/xvda (verified 2026-09 against Marketplace AMI and live Gen2 instances)."
  type        = string
  default     = "/dev/xvda"
}

variable "root_delete_on_termination" {
  description = "(Optional) Delete root volume on termination. Defaults to true."
  type        = bool
  default     = true
}

variable "root_volume_size" {
  description = "(Optional) Root EBS volume size in GiB. Minimum 64 GiB required by the Zscaler Marketplace AMI."
  type        = number
  default     = 75
}

variable "root_volume_type" {
  description = "(Optional) Root EBS volume type. Defaults to gp3."
  type        = string
  default     = "gp3"
  validation {
    condition     = contains(["standard", "gp2", "gp3", "io1", "io2", "sc1", "st1"], var.root_volume_type)
    error_message = "root_volume_type must be one of: standard, gp2, gp3, io1, io2, sc1, st1."
  }
}

variable "http_endpoint" {
  description = "(Optional) Instance metadata service. Valid values: enabled, disabled."
  type        = string
  default     = "enabled"
  validation {
    condition     = contains(["enabled", "disabled"], var.http_endpoint)
    error_message = "http_endpoint must be enabled or disabled."
  }
}

variable "http_tokens" {
  description = "(Optional) IMDSv2 token requirement. Defaults to required."
  type        = string
  default     = "required"
  validation {
    condition     = contains(["optional", "required"], var.http_tokens)
    error_message = "http_tokens must be optional or required."
  }
}

variable "http_put_response_hop_limit" {
  description = "(Optional) IMDSv2 hop limit. Defaults to 1 (Checkov CKV_AWS_341)."
  type        = number
  default     = 1
}

variable "instance_metadata_tags" {
  description = "(Optional) Expose instance tags via metadata. Defaults to enabled."
  type        = string
  default     = "enabled"
  validation {
    condition     = contains(["enabled", "disabled"], var.instance_metadata_tags)
    error_message = "instance_metadata_tags must be enabled or disabled."
  }
}

variable "monitoring" {
  description = "(Optional) Enable detailed CloudWatch monitoring. Defaults to false."
  type        = bool
  default     = false
}

###########################
# Bootstrap / user_data
###########################

variable "provisioning_key" {
  description = "(Required) ZPA App Connector provisioning key from the ZPA admin portal. Mark sensitive in the calling workspace."
  type        = string
  sensitive   = true
}

variable "enable_ssm_agent" {
  description = "(Optional) Install and enable amazon-ssm-agent on first boot. Defaults to true."
  type        = bool
  default     = true
}

variable "enable_host_os_update" {
  description = "(Optional) Run yum update -y on first boot per Zscaler host OS guidance, then reboot. Defaults to false (opt-in). Enabling on a full ASG launch updates every instance at once with no health-gated stagger; a bad kernel/package update can take out the whole group. Prefer a canary LT version or ASG instance refresh with high MinHealthyPercentage when enabling."
  type        = bool
  default     = false
}

###########################
# Auto Scaling Group
###########################

variable "subnet_ids" {
  description = "(Required) Private subnet IDs spanning AZs. For one connector per AZ set desired_capacity equal to length(subnet_ids)."
  type        = list(string)
  validation {
    condition     = length(var.subnet_ids) >= 1
    error_message = "subnet_ids must contain at least one subnet."
  }
}

variable "min_size" {
  description = "(Optional) Minimum number of connectors. Defaults to 3."
  type        = number
  default     = 3
}

variable "desired_capacity" {
  description = "(Optional) Desired number of connectors. Defaults to 3."
  type        = number
  default     = 3
}

variable "max_size" {
  description = "(Optional) Maximum number of connectors. Defaults to 4 for one extra during rolling replace."
  type        = number
  default     = 4
}

variable "health_check_type" {
  description = "(Optional) ASG health check type. Defaults to EC2."
  type        = string
  default     = "EC2"
  validation {
    condition     = contains(["EC2", "ELB"], var.health_check_type)
    error_message = "health_check_type must be EC2 or ELB."
  }
}

variable "health_check_grace_period" {
  description = "(Optional) Seconds after launch before health checks. Defaults to 1200 (20 minutes)."
  type        = number
  default     = 1200
}

variable "default_cooldown" {
  description = "(Optional) ASG default cooldown in seconds. Defaults to 300."
  type        = number
  default     = 300
}

variable "termination_policies" {
  description = "(Optional) Ordered termination policies. Defaults to OldestLaunchTemplate then OldestInstance."
  type        = list(string)
  default     = ["OldestLaunchTemplate", "OldestInstance"]

  validation {
    condition = alltrue([
      for p in var.termination_policies : contains([
        "OldestInstance",
        "NewestInstance",
        "OldestLaunchConfiguration",
        "ClosestToNextInstanceHour",
        "OldestLaunchTemplate",
        "AllocationStrategy",
        "Default",
      ], p)
    ])
    error_message = "termination_policies entries must be one of: OldestInstance, NewestInstance, OldestLaunchConfiguration, ClosestToNextInstanceHour, OldestLaunchTemplate, AllocationStrategy, Default."
  }
}

variable "max_instance_lifetime" {
  description = "(Optional) Maximum instance lifetime in seconds. Defaults to 7776000 (90 days). Use 0 to disable."
  type        = number
  default     = 7776000
  validation {
    condition     = var.max_instance_lifetime == 0 || (var.max_instance_lifetime >= 86400 && var.max_instance_lifetime <= 31536000)
    error_message = "max_instance_lifetime must be 0 (disabled) or between 86400 and 31536000 seconds."
  }
}

variable "capacity_rebalance" {
  description = "(Optional) Enable capacity rebalance. Defaults to false."
  type        = bool
  default     = false
}

variable "enabled_metrics" {
  description = "(Optional) List of ASG group metrics to enable."
  type        = list(string)
  default     = []
}

variable "enable_cpu_target_tracking" {
  description = "(Optional) Attach a CPU target-tracking scaling policy. Defaults to false."
  type        = bool
  default     = false
}

variable "cpu_target_value" {
  description = "(Optional) Target average CPU percent when enable_cpu_target_tracking is true."
  type        = number
  default     = 50
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags assigned to resources created by this module."
  type        = map(string)
  default     = {}
}
