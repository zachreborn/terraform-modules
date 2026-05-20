###########################
# KMS Encryption Key
###########################

variable "key_customer_master_key_spec" {
  description = "(Optional) Specifies whether the key contains a symmetric key or an asymmetric key pair and the encryption algorithms or signing algorithms that the key supports. Valid values: SYMMETRIC_DEFAULT, RSA_2048, RSA_3072, RSA_4096, ECC_NIST_P256, ECC_NIST_P384, ECC_NIST_P521, or ECC_SECG_P256K1. Defaults to SYMMETRIC_DEFAULT. For help with choosing a key spec, see the AWS KMS Developer Guide."
  default     = "SYMMETRIC_DEFAULT"
  type        = string
}

variable "key_description" {
  description = "(Optional) The description of the key as viewed in AWS console."
  default     = "CloudWatch kms key used to encrypt flow logs"
  type        = string
}

variable "key_deletion_window_in_days" {
  description = "(Optional) Duration in days after which the key is deleted after destruction of the resource, must be between 7 and 30 days. Defaults to 30 days."
  default     = 30
  type        = number
}

variable "key_enable_key_rotation" {
  description = "(Optional) Specifies whether key rotation is enabled. Defaults to true."
  default     = true
  type        = bool
}

variable "key_usage" {
  description = "(Optional) Specifies the intended use of the key. Defaults to ENCRYPT_DECRYPT, and only symmetric encryption and decryption are supported."
  default     = "ENCRYPT_DECRYPT"
  type        = string
}

variable "key_is_enabled" {
  description = "(Optional) Specifies whether the key is enabled. Defaults to true."
  default     = true
  type        = string
}

variable "key_name_prefix" {
  description = "(Optional) Creates an unique alias beginning with the specified prefix. The name must start with the word alias followed by a forward slash (alias/)."
  default     = "alias/flow_logs_key_"
  type        = string
}

###########################
# CloudWatch Log Group
###########################

variable "cloudwatch_name_prefix" {
  description = "(Optional, Forces new resource) Creates a unique name beginning with the specified prefix."
  default     = "flow_logs_"
  type        = string
}

variable "cloudwatch_deletion_protection_enabled" {
  description = "(Optional) If true, prevents the log group from being deleted. Defaults to false. Requires AWS provider >= 6.25.0."
  default     = false
  type        = bool
}

variable "cloudwatch_retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Possible values are: 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 3653, and 0. If you select 0, the events in the log group are always retained and never expire."
  default     = 90
  type        = number
}

###########################
# IAM Policy
###########################

variable "iam_policy_description" {
  description = "(Optional, Forces new resource) Description of the IAM policy."
  default     = "Used with flow logs to send packet capture logs to a CloudWatch log group."
  type        = string
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

###########################
# IAM Role
###########################

variable "iam_role_assume_role_policy" {
  type        = string
  description = "(Required) The policy that grants an entity permission to assume the role."
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
  type        = string
  description = "(Optional) The description of the role."
  default     = "Role utilized for EC2 instances ENI flow logs. This role allows creation of log streams and adding logs to the log streams in cloudwatch"
}

variable "iam_role_force_detach_policies" {
  type        = bool
  description = "(Optional) Specifies to force detaching any policies the role has before destroying it. Defaults to false."
  default     = false
}

variable "iam_role_max_session_duration" {
  type        = number
  description = "(Optional) The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
  default     = 3600
}

variable "iam_role_name_prefix" {
  type        = string
  description = "(Required, Forces new resource) Creates a unique friendly name beginning with the specified prefix. Conflicts with name."
  default     = "flow_logs_role_"
}

variable "iam_role_permissions_boundary" {
  type        = string
  description = "(Optional) The ARN of the policy that is used to set the permissions boundary for the role."
  default     = ""
}

###########################
# Flow Log
###########################
variable "flow_deliver_cross_account_role" {
  type        = string
  description = "(Optional) The ARN of the IAM role that posts logs to CloudWatch Logs in a different account."
  default     = null
}

variable "flow_eni_ids" {
  type        = list(string)
  description = "(Optional) List of Elastic Network Interface IDs to attach the flow logs to."
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

variable "flow_subnet_ids" {
  type        = list(string)
  description = "(Optional) List of Subnet IDs to attach the flow logs to."
  default     = null
}

variable "flow_traffic_type" {
  type        = string
  description = "(Optional) The type of traffic to capture. Valid values: ACCEPT,REJECT, ALL."
  default     = "ALL"
}

variable "flow_transit_gateway_ids" {
  type        = list(string)
  description = "(Optional) List of IDs of the transit gateways to attach the flow logs to."
  default     = null
}

variable "flow_transit_gateway_attachment_ids" {
  type        = list(string)
  description = "(Optional) List of IDs of the transit gateway attachments to attach the flow logs to."
  default     = null
}

variable "flow_vpc_ids" {
  type        = list(string)
  description = "(Optional) List of VPC IDs to attach the flow logs to."
  default     = null
}

###############################################################
# General Use Variables
###############################################################

variable "tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the object."
  default = {
    terraform   = "true"
    created_by  = "<YOUR_NAME>"
    environment = "prod"
    priority    = "high"
  }
}
