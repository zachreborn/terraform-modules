###########################
# Transit Gateway Attachment
###########################
variable "transit_gateway_id" {
  description = "(Required) Identifier of EC2 transit gateway."
  type        = string
}

variable "transit_gateway_default_route_table_association" {
  type        = bool
  description = "(Optional) Boolean whether the VPC attachment should be associated with the EC2 transit gateway association default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 transit gateways. Default value: true."
  default     = true
}

variable "transit_gateway_default_route_table_propagation" {
  type        = bool
  description = "(Optional) Boolean whether the VPC attachment should propagate routes with the EC2 transit gateway propagation default route table. This cannot be configured or perform drift detection with Resource Access Manager shared EC2 transit gateways. Default value: true."
  default     = true
}

variable "vpc_ids" {
  description = "(Required) Identifier of the VPC."
  type = map(object({
    appliance_mode_support = optional(string, "disable") # (Optional) Whether Appliance Mode support is enabled. If enabled, a traffic flow between a source and destination uses the same Availability Zone for the VPC attachment for the lifetime of that flow.
    dns_support            = optional(string, "enable")  # (Optional) Whether DNS support is enabled. Valid values: disable, enable. Default value: enable.
    ipv6_support           = optional(string, "disable") # (Optional) Whether IPv6 support is enabled. Valid values: disable, enable. Default value: disable.
    subnet_ids             = list(string)                # (Required) Subnet IDs where the transit gateway attachments will be made. Typically this should be private subnets.
    vpc_id                 = string                      # The VPC ID where the transit gateway attachments will be made.
  }))
  # vpc_ids = {
  #   "transit_vpc" = {
  #     appliance_mode_support = "disable"
  #     dns_support            = "enable"
  #     ipv6_support           = "disable"
  #     subnet_ids             = ["subnet-12345678", "subnet-87654321"]
  #     vpc_id                 = "vpc-12345678"
  #   }
  # }
}

###########################
# Flow Log
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

variable "enable_flow_logs" {
  description = "(Optional) A boolean flag to enable/disable the use of flow logs with the resources. Defaults True."
  default     = true
  type        = bool
}

variable "tags" {
  description = "(Optional) Map of tags for the EC2 transit gateway."
  default = {
    terraform   = "true"
    environment = "prod"
    project     = "core_infrastructure"
  }
  type = map(any)
}
