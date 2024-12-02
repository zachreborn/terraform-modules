terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

locals {
  vpc_ids = { for vpc_id, values in var.vpc_ids : vpc_id => values }
}

###########################
# Transit Gateway Attachment
###########################
resource "aws_ec2_transit_gateway_vpc_attachment" "this" {
  for_each                                        = local.vpc_ids
  appliance_mode_support                          = each.value.appliance_mode_support
  dns_support                                     = each.value.dns_support
  ipv6_support                                    = each.value.ipv6_support
  subnet_ids                                      = each.value.subnet_ids
  tags                                            = merge(tomap({ Name = each.key }), var.tags)
  transit_gateway_id                              = var.transit_gateway_id
  transit_gateway_default_route_table_association = var.transit_gateway_default_route_table_association
  transit_gateway_default_route_table_propagation = var.transit_gateway_default_route_table_propagation
  vpc_id                                          = each.value.vpc_id
}

###########################
# Flow Logs
###########################
module "vpc_flow_logs" {
  source = "../../flow_logs"

  count                               = var.enable_flow_logs ? 1 : 0
  cloudwatch_name_prefix              = var.cloudwatch_name_prefix
  cloudwatch_retention_in_days        = var.cloudwatch_retention_in_days
  iam_policy_name_prefix              = var.iam_policy_name_prefix
  iam_policy_path                     = var.iam_policy_path
  iam_role_description                = var.iam_role_description
  iam_role_name_prefix                = var.iam_role_name_prefix
  key_name_prefix                     = var.key_name_prefix
  flow_deliver_cross_account_role     = var.flow_deliver_cross_account_role
  flow_log_destination_type           = var.flow_log_destination_type
  flow_log_format                     = var.flow_log_format
  flow_max_aggregation_interval       = var.flow_max_aggregation_interval
  flow_traffic_type                   = var.flow_traffic_type
  flow_transit_gateway_attachment_ids = values(aws_ec2_transit_gateway_vpc_attachment.this)[*].id
  tags                                = var.tags
}
