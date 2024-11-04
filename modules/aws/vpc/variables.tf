###########################
# VPC
###########################

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.11.0.0/16"
  type        = string
}

variable "enable_dns_hostnames" {
  description = "(Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults false."
  default     = true
  type        = bool
}

variable "enable_dns_support" {
  description = "(Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults true."
  default     = true
  type        = bool
}

variable "instance_tenancy" {
  description = "A tenancy option for instances launched into the VPC"
  default     = "default"
}

###########################
# VPC Endpoints
###########################

variable "enable_ssm_vpc_endpoints" {
  type        = bool
  description = "(Optional) A boolean flag to enable/disable SSM (Systems Manager) VPC endpoints. Defaults true."
  default     = false
}

###########################
# Subnets
###########################

variable "azs" {
  description = "A list of Availability zones in the region"
  default     = ["us-east-2a", "us-east-2b", "us-east-2c"]
}

variable "db_subnets_list" {
  description = "A list of database subnets inside the VPC."
  default     = ["10.11.11.0/24", "10.11.12.0/24", "10.11.13.0/24"]
}

variable "dmz_subnets_list" {
  description = "A list of DMZ subnets inside the VPC."
  default     = ["10.11.101.0/24", "10.11.102.0/24", "10.11.103.0/24"]
}

variable "map_public_ip_on_launch" {
  description = "(Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is false."
  default     = true
  type        = bool
}

variable "mgmt_subnets_list" {
  description = "A list of mgmt subnets inside the VPC."
  default     = ["10.11.61.0/24", "10.11.62.0/24", "10.11.63.0/24"]
}

variable "private_subnets_list" {
  description = "A list of private subnets inside the VPC."
  default     = ["10.11.1.0/24", "10.11.2.0/24", "10.11.3.0/24"]
}

variable "public_subnets_list" {
  description = "A list of public subnets inside the VPC."
  default     = ["10.11.201.0/24", "10.11.202.0/24", "10.11.203.0/24"]
}

variable "workspaces_subnets_list" {
  description = "A list of workspaces subnets inside the VPC."
  default     = ["10.11.21.0/24", "10.11.22.0/24", "10.11.23.0/24"]
}

###########################
# Gateways
###########################

variable "single_nat_gateway" {
  description = "(Optional) A boolean flag to enable/disable use of only a single shared NAT Gateway across all of your private networks. Defaults False."
  default     = false
}

###########################
# Route Tables and Associations
###########################

variable "db_propagating_vgws" {
  description = "A list of VGWs the db route table should propagate."
  default     = []
}

variable "dmz_propagating_vgws" {
  description = "A list of VGWs the DMZ route table should propagate."
  default     = []
}

variable "fw_dmz_network_interface_id" {
  type        = list(any)
  description = "Firewall DMZ eni id"
  default     = []
}

variable "fw_network_interface_id" {
  description = "Firewall network interface id"
  default     = []
}

variable "mgmt_propagating_vgws" {
  description = "A list of VGWs the mgmt route table should propagate."
  default     = []
}

variable "private_propagating_vgws" {
  description = "A list of VGWs the private route table should propagate."
  default     = []
}

variable "public_propagating_vgws" {
  description = "A list of VGWs the public route table should propagate."
  default     = []
}

variable "workspaces_propagating_vgws" {
  description = "A list of VGWs the workspaces route table should propagate."
  default     = []
}

###########################
# VPC Flow Log
###########################
variable "cloudwatch_name_prefix" {
  description = "(Optional, Forces new resource) Creates a unique name beginning with the specified prefix."
  default     = "flow_logs_"
  type        = string
}

variable "cloudwatch_retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default     = 90
  type        = number
}

variable "iam_policy_name_prefix" {
  description = "(Optional, Forces new resource) Creates a unique name beginning with the specified prefix. Conflicts with name."
  default     = "flow_log_policy_"
  type        = string
}

variable "iam_policy_path" {
  type        = string
  description = "(Optional, default '/') Path in which to create the policy. See IAM Identifiers for more information."
  default     = "/"
}

variable "iam_role_description" {
  type        = string
  description = "(Optional) The description of the role."
  default     = "Role utilized for VPC flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"
}

variable "iam_role_name_prefix" {
  type        = string
  description = "(Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name."
  default     = "flow_logs_role_"
}

variable "key_name_prefix" {
  description = "(Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/)."
  default     = "alias/flow_logs_key_"
  type        = string
}

variable "flow_deliver_cross_account_role" {
  type        = string
  description = "(Optional) The ARN of the IAM role that posts logs to CloudWatch Logs in a different account."
  default     = null
}

variable "flow_log_destination_type" {
  type        = string
  description = "(Optional) The type of the logging destination. Valid values: cloud-watch-logs, s3. Default: cloud-watch-logs."
  default     = "cloud-watch-logs"
}

variable "flow_log_format" {
  type        = string
  description = "(Optional) The fields to include in the flow log record, in the order in which they should appear. For more information, see Flow Log Records. Default: fields are in the order that they are described in the Flow Log Records section."
  default     = null
}

variable "flow_max_aggregation_interval" {
  type        = number
  description = "(Optional) The maximum interval of time during which a flow of packets is captured and aggregated into a flow log record. Valid Values: 60 seconds (1 minute) or 600 seconds (10 minutes). Default: 600."
  default     = 60
}

variable "flow_traffic_type" {
  type        = string
  description = "(Optional) The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."
  default     = "ALL"
}

###############################################################
# General Use Variables
###############################################################

variable "enable_firewall" {
  description = "(Optional) A boolean flag to enable/disable the use of a firewall instance within the VPC. Defaults False."
  default     = false
  type        = bool
}

variable "enable_nat_gateway" {
  description = "(Optional) A boolean flag to enable/disable the use of NAT gateways in the private subnets. Defaults True."
  default     = true
  type        = bool
}

variable "enable_s3_endpoint" {
  description = "(Optional) A boolean flag to enable/disable the use of a S3 endpoint with the VPC. Defaults False"
  default     = false
  type        = bool
}

variable "enable_vpc_flow_logs" {
  description = "(Optional) A boolean flag to enable/disable the use of VPC flow logs with the VPC. Defaults True."
  default     = true
  type        = bool
}

variable "name" {
  description = "(Required) Name to be tagged on all of the resources as an identifier"
  type        = string
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the object."
  default = {
    terraform   = "true"
    created_by  = "<YOUR_NAME>"
    environment = "prod"
    priority    = "high"
  }
}
