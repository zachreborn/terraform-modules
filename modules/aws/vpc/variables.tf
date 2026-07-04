###########################
# VPC
##########################
variable "vpc_cidr" {
  description = "The CIDR block for the VPC. Ignored when ipv4_ipam_pool_id is set, in which case the CIDR is sourced from the IPAM pool."
  type        = string
  default     = "10.11.0.0/16"
}

variable "ipv4_ipam_pool_id" {
  description = "(Optional) The ID of an IPv4 IPAM pool to source the VPC CIDR from. When set, vpc_cidr is ignored and the CIDR is allocated from the pool using ipv4_netmask_length."
  type        = string
  default     = null
}

variable "ipv4_netmask_length" {
  description = "(Optional) The netmask length of the IPv4 CIDR to allocate from the IPAM pool referenced by ipv4_ipam_pool_id. Required when ipv4_ipam_pool_id is set."
  type        = number
  default     = null
}

variable "enable_dns_hostnames" {
  description = "(Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "(Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults true."
  type        = bool
  default     = true
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  type        = string
  default     = "default"
  validation {
    condition     = can(regex("^(default|dedicated)$", var.instance_tenancy))
    error_message = "instance_tenancy must be either default or dedicated"
  }
}

###########################
# VPC Endpoints
###########################

variable "enable_s3_endpoint" {
  description = "(Optional) A boolean flag to enable/disable the use of a S3 endpoint with the VPC."
  type        = bool
  default     = false
}

variable "enable_ssm_vpc_endpoints" {
  description = "(Optional) A boolean flag to enable/disable SSM (Systems Manager) VPC endpoints."
  type        = bool
  default     = false
}

variable "enable_ecr_vpc_endpoints" {
  description = "(Optional) A boolean flag to enable/disable ECR (Elastic Container Registry) VPC endpoints. This enables ECR API, ECR DKR, Cloudwatch Logs, and S3 endpoints."
  type        = bool
  default     = false
}
variable "subnet_indices" {
  description = "List of subnet indices to use (0-2)"
  type        = list(number)
  default     = [0]

  validation {
    condition = alltrue([
      for subnet_index in var.subnet_indices : subnet_index >= 0 && subnet_index <= 2 && length(var.subnet_indices) <= length(var.private_subnets_list)

    ])
    error_message = "Subnet indices must be between 0 and 2."
  }
}
###########################
# Subnets
###########################

variable "azs" {
  description = "A list of Availability zones in the region"
  type        = list(string)
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "enable_private_subnet" {
  description = "(Optional) When true, create the private subnet tier and its route tables/associations. When false, none are created and private-tier outputs return empty lists. Defaults true."
  type        = bool
  default     = true
}

variable "enable_public_subnet" {
  description = "(Optional) When true, create the public subnet tier and its route table associations. When false, none are created and public-tier outputs return empty lists. Also gates the internet gateway / NAT gateway (see notes). Defaults true."
  type        = bool
  default     = true
}

variable "enable_db_subnet" {
  description = "(Optional) When true, create the database subnet tier and its route tables/associations. When false, none are created and db-tier outputs return empty lists. Defaults true."
  type        = bool
  default     = true
}

variable "enable_dmz_subnet" {
  description = "(Optional) When true, create the DMZ subnet tier and its route tables/associations. When false, none are created. Defaults true."
  type        = bool
  default     = true
}

variable "enable_mgmt_subnet" {
  description = "(Optional) When true, create the mgmt subnet tier and its route table/routes. When false, none are created. Defaults true."
  type        = bool
  default     = true
}

variable "enable_workspaces_subnet" {
  description = "(Optional) When true, create the workspaces subnet tier and its route tables/associations. When false, none are created. Defaults true."
  type        = bool
  default     = true
}

variable "db_subnets_list" {
  description = "A list of database subnets inside the VPC."
  type        = list(string)
  default     = ["10.11.11.0/24", "10.11.12.0/24", "10.11.13.0/24"]
}

variable "dmz_subnets_list" {
  description = "A list of DMZ subnets inside the VPC."
  type        = list(string)
  default     = ["10.11.101.0/24", "10.11.102.0/24", "10.11.103.0/24"]
}

variable "map_public_ip_on_launch" {
  description = "(Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false."
  type        = bool
  default     = true
}

variable "mgmt_subnets_list" {
  description = "A list of mgmt subnets inside the VPC."
  type        = list(string)
  default     = ["10.11.61.0/24", "10.11.62.0/24", "10.11.63.0/24"]
}

variable "private_subnets_list" {
  description = "A list of private subnets inside the VPC."
  type        = list(string)
  default     = ["10.11.1.0/24", "10.11.2.0/24", "10.11.3.0/24"]
}

variable "public_subnets_list" {
  description = "A list of public subnets inside the VPC."
  type        = list(string)
  default     = ["10.11.201.0/24", "10.11.202.0/24", "10.11.203.0/24"]
}

variable "workspaces_subnets_list" {
  description = "A list of workspaces subnets inside the VPC."
  type        = list(string)
  default     = ["10.11.21.0/24", "10.11.22.0/24", "10.11.23.0/24"]
}

###########################
# Gateways
###########################

variable "single_nat_gateway" {
  description = "(Optional) A boolean flag to enable/disable use of only a single shared NAT Gateway across all of your private networks. Defaults False."
  type        = bool
  default     = false
}

###########################
# Route Tables and Associations
###########################

variable "db_propagating_vgws" {
  description = "A list of VGWs the db route table should propagate."
  type        = list(string)
  default     = null
}

variable "dmz_propagating_vgws" {
  description = "A list of VGWs the DMZ route table should propagate."
  type        = list(string)
  default     = null
}

variable "fw_dmz_network_interface_id" {
  description = "Firewall DMZ eni id"
  type        = list(string)
  default     = null
}

variable "fw_network_interface_id" {
  description = "Firewall network interface id"
  type        = list(string)
  default     = null
}

variable "mgmt_propagating_vgws" {
  description = "A list of VGWs the mgmt route table should propagate."
  type        = list(any)
  default     = null
}

variable "private_propagating_vgws" {
  description = "A list of VGWs the private route table should propagate."
  type        = list(any)
  default     = null
}

variable "public_propagating_vgws" {
  description = "A list of VGWs the public route table should propagate."
  type        = list(any)
  default     = null
}

variable "workspaces_propagating_vgws" {
  description = "A list of VGWs the workspaces route table should propagate."
  type        = list(any)
  default     = null
}

###########################
# VPC Flow Log
###########################
variable "cloudwatch_name_prefix" {
  description = "(Optional, Forces new resource) Creates a unique name beginning with the specified prefix."
  type        = string
  default     = "flow_logs_"
}

variable "cloudwatch_retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  type        = number
  default     = 90
  validation {
    condition     = can(index([1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, 0], var.cloudwatch_retention_in_days))
    error_message = "cloudwatch_retention_in_days must be one of: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, 0."
  }
}

variable "iam_policy_name_prefix" {
  description = "(Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name."
  type        = string
  default     = "flow_log_policy_"
}

variable "iam_policy_path" {
  description = "(Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information."
  type        = string
  default     = "/"
}

variable "iam_role_description" {
  description = "(Optional) The description of the role."
  type        = string
  default     = "Role utilized for VPC flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"
}

variable "iam_role_name_prefix" {
  description = "(Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name."
  type        = string
  default     = "flow_logs_role_"
}

variable "key_name_prefix" {
  description = "(Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/)."
  type        = string
  default     = "alias/flow_logs_key_"
}

variable "flow_deliver_cross_account_role" {
  description = "(Optional) The ARN of the IAM role that posts logs to CloudWatch Logs in a different account."
  type        = string
  default     = null
}

variable "flow_log_destination_type" {
  description = "(Optional) The type of the logging destination. Valid values: cloud-watch-logs, s3. Default: cloud-watch-logs."
  type        = string
  default     = "cloud-watch-logs"
}

variable "flow_log_format" {
  description = "(Optional) The fields to include in the flow log record, in the order in which they should appear. For more information, see Flow Log Records. Default: fields are in the order that they are described in the Flow Log Records section."
  type        = string
  default     = null
}

variable "flow_max_aggregation_interval" {
  description = "(Optional) The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes). Default: 600."
  type        = number
  default     = 60
}

variable "flow_traffic_type" {
  description = "(Optional) The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."
  type        = string
  default     = "ALL"
  validation {
    condition     = can(index(["ACCEPT", "REJECT", "ALL"], var.flow_traffic_type))
    error_message = "flow_traffic_type must be one of: ACCEPT, REJECT, ALL."
  }
}

###########################
# CloudWatch Internet Monitor
###########################

variable "enable_internet_monitor" {
  description = "(Optional) A boolean flag to enable/disable the creation of a CloudWatch Internet Monitor for this VPC. Defaults false."
  type        = bool
  default     = false
}

variable "internet_monitor_monitor_name" {
  description = "(Optional) The name of the Internet Monitor. Required when enable_internet_monitor is true. Maps to the monitor_name argument."
  type        = string
  default     = null
}

variable "internet_monitor_traffic_percentage_to_monitor" {
  description = "(Optional) The percentage of internet-facing traffic to monitor with this monitor. Valid values are 1-100. Controls cost. Defaults 100."
  type        = number
  default     = 100
  validation {
    condition     = var.internet_monitor_traffic_percentage_to_monitor >= 1 && var.internet_monitor_traffic_percentage_to_monitor <= 100
    error_message = "internet_monitor_traffic_percentage_to_monitor must be between 1 and 100."
  }
}

variable "internet_monitor_max_city_networks_to_monitor" {
  description = "(Optional) The maximum number of city-networks (location + ASN pairs) to monitor. This is a hard billing cap. Valid values are 1-500000. Defaults 100."
  type        = number
  default     = 100
  validation {
    condition     = var.internet_monitor_max_city_networks_to_monitor >= 1 && var.internet_monitor_max_city_networks_to_monitor <= 500000
    error_message = "internet_monitor_max_city_networks_to_monitor must be between 1 and 500000."
  }
}

variable "internet_monitor_status" {
  description = "(Optional) The status for the monitor. Valid values: ACTIVE, INACTIVE. Defaults ACTIVE."
  type        = string
  default     = "ACTIVE"
  validation {
    condition     = can(index(["ACTIVE", "INACTIVE"], var.internet_monitor_status))
    error_message = "internet_monitor_status must be one of: ACTIVE, INACTIVE."
  }
}

variable "internet_monitor_availability_score_threshold" {
  description = "(Optional) The health-event trigger threshold percentage for the availability score. Valid values are 1-100. Defaults 95."
  type        = number
  default     = 95
  validation {
    condition     = var.internet_monitor_availability_score_threshold >= 1 && var.internet_monitor_availability_score_threshold <= 100
    error_message = "internet_monitor_availability_score_threshold must be between 1 and 100."
  }
}

variable "internet_monitor_performance_score_threshold" {
  description = "(Optional) The health-event trigger threshold percentage for the performance score. Valid values are 1-100. Defaults 95."
  type        = number
  default     = 95
  validation {
    condition     = var.internet_monitor_performance_score_threshold >= 1 && var.internet_monitor_performance_score_threshold <= 100
    error_message = "internet_monitor_performance_score_threshold must be between 1 and 100."
  }
}

variable "internet_monitor_s3_bucket_name" {
  description = "(Optional) The name of an existing S3 bucket for publishing internet measurements beyond the top-500 city-networks. When null, S3 measurement delivery is not configured. The bucket must be supplied by the caller."
  type        = string
  default     = null
}

variable "internet_monitor_s3_bucket_prefix" {
  description = "(Optional) The S3 key prefix for internet-measurements delivery."
  type        = string
  default     = null
}

variable "internet_monitor_s3_bucket_status" {
  description = "(Optional) Enables (ENABLED) or disables (DISABLED) S3 internet-measurement delivery. Valid values: ENABLED, DISABLED. Defaults DISABLED."
  type        = string
  default     = "DISABLED"
  validation {
    condition     = can(index(["ENABLED", "DISABLED"], var.internet_monitor_s3_bucket_status))
    error_message = "internet_monitor_s3_bucket_status must be one of: ENABLED, DISABLED."
  }
}

###############################################################
# General Use Variables
###############################################################

variable "enable_firewall" {
  description = "(Optional) A boolean flag to enable/disable the use of a firewall instance within the VPC. Defaults False."
  type        = bool
  default     = false
}

variable "enable_nat_gateway" {
  description = "(Optional) A boolean flag to enable/disable the use of NAT gateways in the private subnets. Defaults True."
  type        = bool
  default     = true
}

variable "enable_internet_gateway" {
  description = "(Optional) A boolean flag to enable/disable the use of Internet gateways. Defaults True."
  type        = bool
  default     = true
}

variable "enable_flow_logs" {
  description = "(Optional) A boolean flag to enable/disable the use of flow logs with the resources. Defaults True."
  type        = bool
  default     = true
}

variable "name" {
  description = "(Required) Name to be tagged on all of the resources as an identifier"
  type        = string
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the object."
  type        = map(string)
  default = {
    terraform   = "true"
    created_by  = "<YOUR_NAME>"
    environment = "prod"
    priority    = "high"
  }
}
