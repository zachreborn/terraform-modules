terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Data Sources
###########################
data "aws_region" "current" {}

###########################
# Locals
###########################

locals {
  # Disable the IGW if either enable_internet_gateway is false or public_subnets_list is empty
  enable_igw = var.enable_internet_gateway && length(var.public_subnets_list) != 0
  # NAT gateways require a public subnet/IGW to attach to, so treat them as
  # disabled whenever the IGW itself is disabled -- consumers of this local
  # (aws_eip.nateip, aws_nat_gateway.natgw, and the *_default_route_natgw
  # routes) must not create resources that reference a NAT gateway that will
  # never exist.
  enable_natgw = var.enable_nat_gateway && local.enable_igw
  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

###########################
# VPC
###########################

resource "aws_vpc" "vpc" {
  # When ipv4_ipam_pool_id is set, the CIDR is sourced from the IPAM pool and
  # cidr_block must be null; otherwise fall back to the static vpc_cidr.
  cidr_block           = var.ipv4_ipam_pool_id == null ? var.vpc_cidr : null
  ipv4_ipam_pool_id    = var.ipv4_ipam_pool_id
  ipv4_netmask_length  = var.ipv4_netmask_length
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy
  tags                 = merge(tomap({ Name = var.name }), var.tags)
}


###########################
# VPC Endpoints
###########################

resource "aws_security_group" "ssm_vpc_endpoint" {
  description = "SSM VPC service endpoint SG."
  name        = "ssm_vpc_endpoint_sg"
  tags        = merge({ Name = "ssm_vpc_endpoint_sg" }, var.tags)
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "VPC endpoint communication over HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    # Reference the VPC's resolved CIDR so IPAM-sourced VPCs (where the CIDR is
    # not known until apply) work without requiring a separate vpc_cidr value.
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  ingress {
    description = "VPC endpoint communication over HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = [aws_vpc.vpc.cidr_block]
  }

  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    # Allow VPC endpoint outbound traffic to VPC endpoint
    #tfsec:ignore:aws-ec2-no-public-egress-sgr
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# SSM VPC Endpoints
resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ec2messages"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "kms" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.kms"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssm" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssm-contacts" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm-contacts"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssm-incidents" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm-incidents"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssmmessages"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

# ECR VPC Endpoints
resource "aws_vpc_endpoint" "ecr_api" {
  count               = var.enable_ecr_vpc_endpoints ? 1 : 0
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ecr.api"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  subnet_ids          = toset(aws_subnet.private_subnets[*].id)
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.vpc.id
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_ecr_vpc_endpoints ? 1 : 0
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  subnet_ids          = toset(aws_subnet.private_subnets[*].id)
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.vpc.id
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

# Cloudwatch Logs Endpoint
resource "aws_vpc_endpoint" "cloudwatch" {
  count               = var.enable_ecr_vpc_endpoints ? 1 : 0
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.region}.logs"
  security_group_ids  = [aws_security_group.ssm_vpc_endpoint.id]
  subnet_ids          = toset(aws_subnet.private_subnets[*].id)
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.vpc.id
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

# S3 Endpoint
resource "aws_vpc_endpoint" "s3" {
  count             = var.enable_s3_endpoint || var.enable_ecr_vpc_endpoints ? 1 : 0
  service_name      = local.service_name
  tags              = merge(tomap({ Name = var.name }), var.tags)
  vpc_endpoint_type = "Gateway"
  vpc_id            = aws_vpc.vpc.id
}

resource "aws_vpc_endpoint_route_table_association" "private_s3" {
  count           = (var.enable_s3_endpoint || var.enable_ecr_vpc_endpoints) ? length(aws_route_table.private_route_table[*].id) : 0
  route_table_id  = element(aws_route_table.private_route_table[*].id, count.index)
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

resource "aws_vpc_endpoint_route_table_association" "public_s3" {
  count           = (var.enable_s3_endpoint || var.enable_ecr_vpc_endpoints) ? length(aws_route_table.public_route_table[*].id) : 0
  route_table_id  = element(aws_route_table.public_route_table[*].id, count.index)
  vpc_endpoint_id = aws_vpc_endpoint.s3[0].id
}

###########################
# Subnets
###########################

resource "aws_subnet" "private_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.private_subnets_list[count.index]
  availability_zone = element(var.azs, count.index)
  count             = length(var.private_subnets_list)
  tags              = merge(var.tags, ({ "Name" = format("%s-subnet-private-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnets_list[count.index]
  availability_zone = element(var.azs, count.index)
  # Allow public IP assignment for public subnets and zone
  #tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch = var.map_public_ip_on_launch
  count                   = length(var.public_subnets_list)
  tags                    = merge(var.tags, ({ "Name" = format("%s-subnet-public-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "dmz_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.dmz_subnets_list[count.index]
  availability_zone = element(var.azs, count.index)
  count             = length(var.dmz_subnets_list)
  tags              = merge(var.tags, ({ "Name" = format("%s-subnet-dmz-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "db_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.db_subnets_list[count.index]
  availability_zone = element(var.azs, count.index)
  count             = length(var.db_subnets_list)
  tags              = merge(var.tags, ({ "Name" = format("%s-subnet-db-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "mgmt_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.mgmt_subnets_list[count.index]
  availability_zone = element(var.azs, count.index)
  count             = length(var.mgmt_subnets_list)
  tags              = merge(var.tags, ({ "Name" = format("%s-subnet-mgmt-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "workspaces_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.workspaces_subnets_list[count.index]
  availability_zone = element(var.azs, count.index)
  count             = length(var.workspaces_subnets_list)
  tags              = merge(var.tags, ({ "Name" = format("%s-subnet-workspaces-%s", var.name, element(var.azs, count.index)) }))
}

###########################
# Gateways
###########################

resource "aws_internet_gateway" "igw" {
  count  = local.enable_igw ? 1 : 0
  tags   = merge(var.tags, ({ "Name" = format("%s-igw", var.name) }))
  vpc_id = aws_vpc.vpc.id
}

resource "aws_route_table" "public_route_table" {
  count            = local.enable_igw ? 1 : 0
  propagating_vgws = var.public_propagating_vgws
  tags             = merge(var.tags, ({ "Name" = format("%s-rt-public", var.name) }))
  vpc_id           = aws_vpc.vpc.id
}

resource "aws_route" "public_default_route" {
  count                  = local.enable_igw ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
  route_table_id         = aws_route_table.public_route_table[0].id
}

resource "aws_eip" "nateip" {
  count  = local.enable_natgw ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  depends_on = [aws_internet_gateway.igw]

  count         = local.enable_natgw ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  allocation_id = element(aws_eip.nateip[*].id, (var.single_nat_gateway ? 0 : count.index))
  subnet_id     = element(aws_subnet.public_subnets[*].id, (var.single_nat_gateway ? 0 : count.index))
}

###########################
# Route Tables and Associations
###########################

resource "aws_route_table" "private_route_table" {
  count            = length(var.private_subnets_list)
  propagating_vgws = var.private_propagating_vgws
  tags             = merge(var.tags, ({ "Name" = format("%s-rt-private-%s", var.name, element(var.azs, count.index)) }))
  vpc_id           = aws_vpc.vpc.id
}

resource "aws_route" "private_default_route_natgw" {
  count                  = (var.enable_nat_gateway && local.enable_igw && length(var.private_subnets_list) > 0) ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.natgw[*].id, count.index)
  route_table_id         = element(aws_route_table.private_route_table[*].id, count.index)
}

resource "aws_route" "private_default_route_fw" {
  count                  = var.enable_firewall ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = element(var.fw_network_interface_id, count.index)
  route_table_id         = element(aws_route_table.private_route_table[*].id, count.index)
}

resource "aws_route_table" "db_route_table" {
  count            = length(var.db_subnets_list)
  propagating_vgws = var.db_propagating_vgws
  tags             = merge(var.tags, ({ "Name" = format("%s-rt-db-%s", var.name, element(var.azs, count.index)) }))
  vpc_id           = aws_vpc.vpc.id
}

resource "aws_route" "db_default_route_natgw" {
  count                  = (var.enable_nat_gateway && local.enable_igw && length(var.db_subnets_list) > 0) ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.natgw[*].id, count.index)
  route_table_id         = element(aws_route_table.db_route_table[*].id, count.index)
}

resource "aws_route" "db_default_route_fw" {
  count                  = var.enable_firewall ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = element(var.fw_network_interface_id, count.index)
  route_table_id         = element(aws_route_table.db_route_table[*].id, count.index)
}

resource "aws_route_table" "dmz_route_table" {
  count            = length(var.dmz_subnets_list)
  propagating_vgws = var.dmz_propagating_vgws
  tags             = merge(var.tags, ({ "Name" = format("%s-rt-dmz-%s", var.name, element(var.azs, count.index)) }))
  vpc_id           = aws_vpc.vpc.id
}

resource "aws_route" "dmz_default_route_natgw" {
  count                  = (var.enable_nat_gateway && local.enable_igw && length(var.dmz_subnets_list) > 0) ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.natgw[*].id, count.index)
  route_table_id         = element(aws_route_table.dmz_route_table[*].id, count.index)
}

resource "aws_route" "dmz_default_route_fw" {
  count                  = var.enable_firewall ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = element(var.fw_dmz_network_interface_id, count.index)
  route_table_id         = element(aws_route_table.dmz_route_table[*].id, count.index)
}

resource "aws_route_table" "mgmt_route_table" {
  count            = length(var.mgmt_subnets_list)
  propagating_vgws = var.mgmt_propagating_vgws
  tags             = merge(var.tags, ({ "Name" = format("%s-rt-mgmt-%s", var.name, element(var.azs, count.index)) }))
  vpc_id           = aws_vpc.vpc.id
}

resource "aws_route" "mgmt_default_route_natgw" {
  count                  = (var.enable_nat_gateway && local.enable_igw && length(var.mgmt_subnets_list) > 0) ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.natgw[*].id, count.index)
  route_table_id         = element(aws_route_table.mgmt_route_table[*].id, count.index)
}

resource "aws_route" "mgmt_default_route_fw" {
  count                  = var.enable_firewall ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = element(var.fw_network_interface_id, count.index)
  route_table_id         = element(aws_route_table.mgmt_route_table[*].id, count.index)
}

resource "aws_route_table" "workspaces_route_table" {
  count            = length(var.workspaces_subnets_list)
  propagating_vgws = var.workspaces_propagating_vgws
  tags             = merge(var.tags, ({ "Name" = format("%s-rt-workspaces-%s", var.name, element(var.azs, count.index)) }))
  vpc_id           = aws_vpc.vpc.id
}

resource "aws_route" "workspaces_default_route_natgw" {
  count                  = (var.enable_nat_gateway && local.enable_igw && length(var.workspaces_subnets_list) > 0) ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = element(aws_nat_gateway.natgw[*].id, count.index)
  route_table_id         = element(aws_route_table.workspaces_route_table[*].id, count.index)
}

resource "aws_route" "workspaces_default_route_fw" {
  count                  = var.enable_firewall ? length(var.azs) : 0
  destination_cidr_block = "0.0.0.0/0"
  network_interface_id   = element(var.fw_network_interface_id, count.index)
  route_table_id         = element(aws_route_table.workspaces_route_table[*].id, count.index)
}



resource "aws_route_table_association" "private" {
  count          = length(var.private_subnets_list)
  route_table_id = element(aws_route_table.private_route_table[*].id, count.index)
  subnet_id      = element(aws_subnet.private_subnets[*].id, count.index)
}

resource "aws_route_table_association" "public" {
  count          = local.enable_igw ? length(var.public_subnets_list) : 0
  route_table_id = aws_route_table.public_route_table[0].id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

resource "aws_route_table_association" "db" {
  count          = length(var.db_subnets_list)
  route_table_id = element(aws_route_table.db_route_table[*].id, count.index)
  subnet_id      = element(aws_subnet.db_subnets[*].id, count.index)
}

resource "aws_route_table_association" "dmz" {
  count          = length(var.dmz_subnets_list)
  route_table_id = element(aws_route_table.dmz_route_table[*].id, count.index)
  subnet_id      = element(aws_subnet.dmz_subnets[*].id, count.index)
}

resource "aws_route_table_association" "workspaces" {
  count          = length(var.workspaces_subnets_list)
  route_table_id = element(aws_route_table.workspaces_route_table[*].id, count.index)
  subnet_id      = element(aws_subnet.workspaces_subnets[*].id, count.index)
}

######################################################
# VPC Flow Logs
######################################################

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
  flow_vpc_ids                    = [aws_vpc.vpc.id]
  tags                            = var.tags
}

###########################
# CloudWatch Internet Monitor
###########################

resource "aws_internetmonitor_monitor" "this" {
  count = var.enable_internet_monitor ? 1 : 0

  monitor_name                  = var.internet_monitor_monitor_name
  resources                     = [aws_vpc.vpc.arn]
  status                        = var.internet_monitor_status
  traffic_percentage_to_monitor = var.internet_monitor_traffic_percentage_to_monitor
  max_city_networks_to_monitor  = var.internet_monitor_max_city_networks_to_monitor
  tags                          = merge(tomap({ Name = var.name }), var.tags)

  health_events_config {
    availability_score_threshold = var.internet_monitor_availability_score_threshold
    performance_score_threshold  = var.internet_monitor_performance_score_threshold
  }

  # Only wire S3 measurement delivery when the caller supplies a bucket name.
  dynamic "internet_measurements_log_delivery" {
    for_each = var.internet_monitor_s3_bucket_name != null ? [1] : []
    content {
      s3_config {
        bucket_name         = var.internet_monitor_s3_bucket_name
        bucket_prefix       = var.internet_monitor_s3_bucket_prefix
        log_delivery_status = var.internet_monitor_s3_bucket_status
      }
    }
  }

  lifecycle {
    # required_version (>= 1.0.0) predates cross-variable validation, so enforce
    # the "monitor_name required when enabled" contract with a precondition.
    precondition {
      condition     = !var.enable_internet_monitor || var.internet_monitor_monitor_name != null
      error_message = "internet_monitor_monitor_name must be set when enable_internet_monitor is true."
    }
  }
}
