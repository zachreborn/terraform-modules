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
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###########################
# Locals
###########################

locals {
  # Disable the IGW if either enable_internet_gateway is false or public_subnets_list is empty
  enable_igw   = var.enable_internet_gateway ? ((length(var.public_subnets_list) != 0 || var.public_subnets_list != null) ? true : false) : false
  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"
}

###########################
# VPC
###########################

resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support
  instance_tenancy     = var.instance_tenancy
  tags                 = merge(tomap({ Name = var.name }), var.tags)
}


###########################
# VPC Endpoints
###########################

resource "aws_security_group" "ssm_vpc_endpoint" {
  description = "SSM VPC service endpoint SG"
  name        = "ssm_vpc_endpoint_sg"
  tags        = merge({ Name = "ssm_vpc_endpoint_sg" }, var.tags)
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "VPC endpoint communication over HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "VPC endpoint communication over HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
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
  count            = length(var.public_subnets_list) != 0 ? 1 : 0
  propagating_vgws = var.public_propagating_vgws
  tags             = merge(var.tags, ({ "Name" = format("%s-rt-public", var.name) }))
  vpc_id           = aws_vpc.vpc.id
}

# !FIX: We should probably update this to just disable the igw if there are no public subnets present and default to disable since we are unlikely to use it in our infra.  
resource "aws_route" "public_default_route" {
  count                  = local.enable_igw ? 1 : 0
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw[0].id
  route_table_id         = aws_route_table.public_route_table[0].id
}

resource "aws_eip" "nateip" {
  count  = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0
  domain = "vpc"
}

resource "aws_nat_gateway" "natgw" {
  depends_on = [aws_internet_gateway.igw]

  count         = var.enable_nat_gateway ? (local.enable_igw ? (var.single_nat_gateway ? 1 : length(var.azs)) : 0) : 0
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
  count                  = (var.enable_nat_gateway && length(var.private_subnets_list) > 0) ? length(var.azs) : 0
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
  count                  = (var.enable_nat_gateway && length(var.db_subnets_list) > 0) ? length(var.azs) : 0
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
  count                  = (var.enable_nat_gateway && length(var.dmz_subnets_list) > 0) ? length(var.azs) : 0
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
  count                  = (var.enable_nat_gateway && length(var.mgmt_subnets_list) > 0) ? length(var.azs) : 0
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
  count                  = (var.enable_nat_gateway && length(var.workspaces_subnets_list) > 0) ? length(var.azs) : 0
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
  count          = length(var.public_subnets_list)
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
