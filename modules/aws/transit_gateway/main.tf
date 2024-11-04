terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Transit Gateway
###########################

resource "aws_ec2_transit_gateway" "transit_gateway" {
  description                     = var.description
  amazon_side_asn                 = var.amazon_side_asn
  auto_accept_shared_attachments  = var.auto_accept_shared_attachments
  default_route_table_association = var.default_route_table_association
  default_route_table_propagation = var.default_route_table_propagation
  dns_support                     = var.dns_support
  tags                            = merge(tomap({ Name = var.name }), var.tags)
  transit_gateway_cidr_blocks     = var.transit_gateway_cidr_blocks
  vpn_ecmp_support                = var.vpn_ecmp_support
}

###########################
# Flow Logs
###########################

module "vpc_flow_logs" {
  source = "../flow_logs"

  count                           = var.enable_flow_logs ? 1 : 0
  cloudwatch_name_prefix          = var.cloudwatch_name_prefix
  cloudwatch_retention_in_days    = var.cloudwatch_retention_in_days
  iam_policy_name_prefix          = var.iam_policy_name_prefix
  iam_policy_path                 = var.iam_policy_path
  iam_role_description            = var.iam_role_description
  iam_role_name_prefix            = var.iam_role_name_prefix
  key_name_prefix                 = var.key_name_prefix
  flow_deliver_cross_account_role = var.flow_deliver_cross_account_role
  flow_log_destination_type       = var.flow_log_destination_type
  flow_log_format                 = var.flow_log_format
  flow_max_aggregation_interval   = var.flow_max_aggregation_interval
  flow_traffic_type               = var.flow_traffic_type
  flow_transit_gateway_id         = aws_ec2_transit_gateway.transit_gateway.id
  tags                            = var.tags
}
