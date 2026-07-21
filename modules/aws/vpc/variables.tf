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

variable "enable_ipv6" {
  description = "(Optional) A boolean flag to enable/disable dual-stack IPv6 support. When true and ipv6_ipam_pool_id is not set, an Amazon-provided /56 IPv6 CIDR is auto-assigned to the VPC (assign_generated_ipv6_cidr_block). Every subnet this module manages then receives a /64 carved out of that block, an egress-only internet gateway is created, and IPv6 default routes (::/0) are added alongside the existing IPv4 defaults. Defaults false (IPv4-only)."
  type        = bool
  default     = false
}

variable "ipv6_ipam_pool_id" {
  description = "(Optional) The ID of an IPv6 IPAM pool to source the VPC's IPv6 CIDR from. When set, the VPC requests its IPv6 CIDR from this pool (via ipv6_cidr_block/ipv6_netmask_length) instead of an Amazon-provided block. Only used when enable_ipv6 is true."
  type        = string
  default     = null
}

variable "ipv6_cidr_block" {
  description = "(Optional) A specific IPv6 CIDR to request from the IPAM pool referenced by ipv6_ipam_pool_id. Leave null to let IPAM choose a CIDR automatically using ipv6_netmask_length."
  type        = string
  default     = null
}

variable "ipv6_netmask_length" {
  description = "(Optional) The netmask length of the IPv6 CIDR to allocate from ipv6_ipam_pool_id. Valid values are 44-60 in increments of 4. Also used (regardless of ipv6_ipam_pool_id) to compute the /64 subnet carve-out math; defaults to 56, matching the fixed prefix length AWS assigns for Amazon-provided IPv6 CIDRs."
  type        = number
  default     = 56
}

variable "ipv6_cidr_block_network_border_group" {
  description = "(Optional) The Network Border Group (e.g. a Local Zone) to restrict IPv6 address advertisement to. Defaults to the VPC's region when null."
  type        = string
  default     = null
}

variable "enable_dns_hostnames" {
  description = "(Optional) A boolean flag to enable/disable DNS hostnames in the VPC. Defaults true."
  type        = bool
  default     = true
}

variable "enable_dns_support" {
  description = "(Optional) A boolean flag to enable/disable DNS support in the VPC. Defaults true."
  type        = bool
  default     = true
}

variable "enable_network_address_usage_metrics" {
  description = "(Optional) Indicates whether Network Address Usage metrics are enabled for the VPC. Defaults false."
  type        = bool
  default     = false
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
  description = "(Optional) List of indices into private_subnets_list identifying which private subnets the SSM VPC endpoints (enable_ssm_vpc_endpoints) should be placed in. Defaults to just the first private subnet to minimize per-AZ interface endpoint charges; add more indices to spread SSM endpoints across additional AZs. Unlike the SSM endpoints, the ECR/CloudWatch Logs endpoints (enable_ecr_vpc_endpoints) are always placed in every private subnet, since container image pulls must succeed from workloads in any AZ."
  type        = list(number)
  default     = [0]

  validation {
    condition = alltrue([
      for subnet_index in var.subnet_indices : subnet_index >= 0 && subnet_index <= max(length(var.private_subnets_list) - 1, 0) && length(var.subnet_indices) <= length(var.private_subnets_list)
    ])
    error_message = "Subnet indices must reference valid, unique positions within private_subnets_list (0 to length(private_subnets_list) - 1)."
  }
}

variable "vpc_endpoints" {
  description = "(Optional) Map of additional VPC endpoints to create, keyed by an arbitrary, unique endpoint name. Use this to attach any Interface, Gateway, GatewayLoadBalancer, Resource, or ServiceNetwork endpoint not covered by enable_ssm_vpc_endpoints/enable_ecr_vpc_endpoints/enable_s3_endpoint, without editing this module (e.g. Secrets Manager, STS, EC2, SNS/SQS). Gateway-type endpoints default to being associated with every public and private route table this module manages unless route_table_ids is set explicitly. Each entry must set exactly one of service_name, resource_configuration_arn, or service_network_arn."
  type = map(object({
    service_name               = optional(string)
    resource_configuration_arn = optional(string)
    service_network_arn        = optional(string)
    service_region             = optional(string)
    vpc_endpoint_type          = optional(string, "Interface")
    auto_accept                = optional(bool)
    policy                     = optional(string)
    private_dns_enabled        = optional(bool, false)
    ip_address_type            = optional(string)
    security_group_ids         = optional(list(string), [])
    subnet_ids                 = optional(list(string))
    route_table_ids            = optional(list(string))
    tags                       = optional(map(string), {})
    dns_options = optional(object({
      dns_record_ip_type                             = optional(string)
      private_dns_only_for_inbound_resolver_endpoint = optional(bool)
      private_dns_preference                         = optional(string)
      private_dns_specified_domains                  = optional(list(string))
    }))
    subnet_configuration = optional(list(object({
      ipv4      = optional(string)
      ipv6      = optional(string)
      subnet_id = optional(string)
    })), [])
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vpc_endpoints :
      (v.service_name != null ? 1 : 0) + (v.resource_configuration_arn != null ? 1 : 0) + (v.service_network_arn != null ? 1 : 0) == 1
    ])
    error_message = "Each vpc_endpoints entry must set exactly one of service_name, resource_configuration_arn, or service_network_arn."
  }

  validation {
    condition = alltrue([
      for k, v in var.vpc_endpoints : contains(["Gateway", "GatewayLoadBalancer", "Interface", "Resource", "ServiceNetwork"], v.vpc_endpoint_type)
    ])
    error_message = "Each vpc_endpoints entry's vpc_endpoint_type must be one of: Gateway, GatewayLoadBalancer, Interface, Resource, ServiceNetwork."
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
  description = "(Optional) Specify true to indicate that instances launched into the subnet should be assigned a public IP address. Default is true."
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

variable "additional_routes" {
  description = "(Optional) Map of additional routes to add to this module's managed route tables, for destinations not covered by the built-in IGW/NAT/firewall/IPv6 defaults (e.g. VPC peering, Transit Gateway, prefix lists, carrier gateway, Outposts local gateway, ODB network, VPC Lattice). Each key is an arbitrary, unique route name. route_table_types selects which of this module's route table tiers (private, public, db, dmz, mgmt, workspaces) the route is added to; the same route is replicated across every route table this module manages in each selected tier. route_table_types must be a non-empty list of unique, supported tier names."
  type = map(object({
    route_table_types           = list(string)
    destination_cidr_block      = optional(string)
    destination_ipv6_cidr_block = optional(string)
    destination_prefix_list_id  = optional(string)
    vpc_peering_connection_id   = optional(string)
    transit_gateway_id          = optional(string)
    carrier_gateway_id          = optional(string)
    core_network_arn            = optional(string)
    vpc_endpoint_id             = optional(string)
    network_interface_id        = optional(string)
    egress_only_gateway_id      = optional(string)
    nat_gateway_id              = optional(string)
    gateway_id                  = optional(string)
    local_gateway_id            = optional(string)
    odb_network_arn             = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for route in var.additional_routes :
      length(route.route_table_types) > 0
      && length(route.route_table_types) == length(distinct(route.route_table_types))
      && alltrue([for rtt in route.route_table_types : contains(["private", "public", "db", "dmz", "mgmt", "workspaces"], rtt)])
    ])
    error_message = "Each additional_routes entry's route_table_types must be a non-empty list of unique values, each one of: private, public, db, dmz, mgmt, workspaces."
  }
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

variable "cloudwatch_deletion_protection_enabled" {
  description = "(Optional) If true, prevents the flow logs' CloudWatch log group from being deleted. Defaults false. Requires AWS provider >= 6.25.0. Passed through to modules/aws/flow_logs."
  type        = bool
  default     = false
}

variable "iam_policy_description" {
  description = "(Optional, Forces new resource) Description of the flow logs IAM policy. Passed through to modules/aws/flow_logs."
  type        = string
  default     = "Used with flow logs to send packet capture logs to a CloudWatch log group."
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

variable "iam_role_assume_role_policy" {
  description = "(Optional) The policy that grants the flow logs service permission to assume the IAM role. Passed through to modules/aws/flow_logs."
  type        = string
  default     = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

variable "iam_role_description" {
  description = "(Optional) The description of the role."
  type        = string
  default     = "Role utilized for VPC flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"
}

variable "iam_role_force_detach_policies" {
  description = "(Optional) Specifies to force detaching any policies the flow logs role has before destroying it. Defaults false. Passed through to modules/aws/flow_logs."
  type        = bool
  default     = false
}

variable "iam_role_max_session_duration" {
  description = "(Optional) The maximum session duration (in seconds, 3600-43200) for the flow logs IAM role. Passed through to modules/aws/flow_logs."
  type        = number
  default     = 3600
}

variable "iam_role_name_prefix" {
  description = "(Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name."
  type        = string
  default     = "flow_logs_role_"
}

variable "iam_role_permissions_boundary" {
  description = "(Optional) The ARN of the policy used to set the permissions boundary for the flow logs IAM role. Passed through to modules/aws/flow_logs."
  type        = string
  default     = null
}

variable "key_customer_master_key_spec" {
  description = "(Optional) Specifies whether the flow logs KMS key contains a symmetric key or an asymmetric key pair. Defaults SYMMETRIC_DEFAULT. Passed through to modules/aws/flow_logs."
  type        = string
  default     = "SYMMETRIC_DEFAULT"
}

variable "key_description" {
  description = "(Optional) The description of the flow logs KMS key as viewed in the AWS console. Passed through to modules/aws/flow_logs."
  type        = string
  default     = "CloudWatch kms key used to encrypt flow logs"
}

variable "key_deletion_window_in_days" {
  description = "(Optional) Duration in days (7-30) after which the flow logs KMS key is deleted after destruction of the resource. Defaults 30. Passed through to modules/aws/flow_logs."
  type        = number
  default     = 30
}

variable "key_enable_key_rotation" {
  description = "(Optional) Specifies whether automatic rotation is enabled for the flow logs KMS key. Defaults true. Passed through to modules/aws/flow_logs."
  type        = bool
  default     = true
}

variable "key_usage" {
  description = "(Optional) Specifies the intended use of the flow logs KMS key. Defaults ENCRYPT_DECRYPT. Passed through to modules/aws/flow_logs."
  type        = string
  default     = "ENCRYPT_DECRYPT"
}

variable "key_is_enabled" {
  description = "(Optional) Specifies whether the flow logs KMS key is enabled. Defaults true. Passed through to modules/aws/flow_logs."
  type        = bool
  default     = true
}

variable "key_name_prefix" {
  description = "(Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/)."
  type        = string
  default     = "alias/flow_logs_key_"
}

variable "flow_eni_ids" {
  description = "(Optional) List of Elastic Network Interface IDs to attach the flow logs to, instead of this module's own VPC. The underlying flow_logs module only supports one flow-log target at a time, so setting this makes the flow log target these ENIs and suppresses the default VPC target. Passed through to modules/aws/flow_logs."
  type        = list(string)
  default     = null
}

variable "flow_subnet_ids" {
  description = "(Optional) List of Subnet IDs to attach the flow logs to, instead of this module's own VPC. The underlying flow_logs module only supports one flow-log target at a time, so setting this makes the flow log target these subnets and suppresses the default VPC target. Passed through to modules/aws/flow_logs."
  type        = list(string)
  default     = null
}

variable "flow_transit_gateway_ids" {
  description = "(Optional) List of IDs of the transit gateways to attach the flow logs to, instead of this module's own VPC. The underlying flow_logs module only supports one flow-log target at a time, so setting this makes the flow log target these transit gateways and suppresses the default VPC target. Passed through to modules/aws/flow_logs."
  type        = list(string)
  default     = null
}

variable "flow_transit_gateway_attachment_ids" {
  description = "(Optional) List of IDs of the transit gateway attachments to attach the flow logs to, instead of this module's own VPC. The underlying flow_logs module only supports one flow-log target at a time, so setting this makes the flow log target these attachments and suppresses the default VPC target. Passed through to modules/aws/flow_logs."
  type        = list(string)
  default     = null
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

  validation {
    condition     = !var.enable_internet_monitor || var.internet_monitor_monitor_name != null
    error_message = "internet_monitor_monitor_name must be set when enable_internet_monitor is true."
  }
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
