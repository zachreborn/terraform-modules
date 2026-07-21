terraform {
  # >= 1.9.0: this module's variable validation blocks (subnet_indices,
  # internet_monitor_monitor_name) reference other variables
  # (e.g. var.private_subnets_list), which OpenTofu and Terraform both only
  # support starting in their respective 1.9.0 releases.
  required_version = ">= 1.9.0"
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
  # NAT gateways require a public subnet/IGW to attach to, so treat NAT-gateway
  # resources as disabled whenever the IGW itself is disabled. NAT-dependent
  # routes are gated on local.enable_igw to avoid referencing a NAT gateway that
  # will never exist.
  enable_natgw = var.enable_nat_gateway && local.enable_igw
  service_name = "com.amazonaws.${data.aws_region.current.region}.s3"

  # IPv6: every subnet gets a /64, carved out of the VPC's own IPv6 prefix.
  # newbits below is how many extra bits distinguish each /64 within that
  # block. The VPC's actual prefix length depends on how the CIDR was
  # sourced (in priority order):
  #   1. An explicit ipv6_cidr_block (from an IPAM pool) -- derive the
  #      prefix from that CIDR's own suffix, since it may not match
  #      ipv6_netmask_length (e.g. a /52 explicit CIDR with the default
  #      ipv6_netmask_length of 56 left unset).
  #   2. ipv6_netmask_length (IPAM auto-selects a CIDR of this size).
  #   3. 56, the fixed prefix length for an Amazon-provided IPv6 CIDR.
  # This is computed from input variables only (never from the VPC's own
  # possibly-unknown-until-apply ipv6_cidr_block attribute) so it's always
  # known at plan time.
  ipv6_prefix_length = (
    var.enable_ipv6 && var.ipv6_ipam_pool_id != null && var.ipv6_cidr_block != null
    ? tonumber(split("/", var.ipv6_cidr_block)[1])
    : (var.enable_ipv6 && var.ipv6_ipam_pool_id != null && var.ipv6_netmask_length != null ? var.ipv6_netmask_length : 56)
  )
  ipv6_newbits = 64 - local.ipv6_prefix_length

  # Sequential per-tier offsets into the VPC's IPv6 CIDR so every subnet
  # (across all tiers) gets a unique /64 block. Tiers are ordered private,
  # public, dmz, db, mgmt, workspaces.
  ipv6_private_offset    = 0
  ipv6_public_offset     = local.ipv6_private_offset + length(var.private_subnets_list)
  ipv6_dmz_offset        = local.ipv6_public_offset + length(var.public_subnets_list)
  ipv6_db_offset         = local.ipv6_dmz_offset + length(var.dmz_subnets_list)
  ipv6_mgmt_offset       = local.ipv6_db_offset + length(var.db_subnets_list)
  ipv6_workspaces_offset = local.ipv6_mgmt_offset + length(var.mgmt_subnets_list)

  # Route table IDs grouped by tier, used to fan additional_routes out across
  # every route table this module manages in the caller-selected tiers.
  route_table_ids_by_type = {
    private    = aws_route_table.private_route_table[*].id
    public     = aws_route_table.public_route_table[*].id
    db         = aws_route_table.db_route_table[*].id
    dmz        = aws_route_table.dmz_route_table[*].id
    mgmt       = aws_route_table.mgmt_route_table[*].id
    workspaces = aws_route_table.workspaces_route_table[*].id
  }

  additional_routes_flat = flatten([
    for route_key, route in var.additional_routes : [
      for rtt in route.route_table_types : [
        for idx, rt_id in lookup(local.route_table_ids_by_type, rtt, []) : {
          key            = "${route_key}-${rtt}-${idx}"
          route_table_id = rt_id
          route          = route
        }
      ]
    ]
  ])

  additional_routes_by_key = { for item in local.additional_routes_flat : item.key => item }
}

###########################
# VPC
###########################

resource "aws_vpc" "vpc" {
  # Flow logging is enabled by default via the composed vpc_flow_logs module
  # below (var.enable_flow_logs defaults to true), which targets this VPC by
  # default through the flow_vpc_ids expression (see that module block).
  # Checkov's static graph resolution can't trace flow_vpc_ids's conditional
  # expression -- it depends on whether the caller supplied any alternate
  # flow-log target -- through the module boundary back to this aws_vpc
  # resource, so it reports a false positive here.
  # checkov:skip=CKV2_AWS_11:Flow logging is enabled by default via the composed vpc_flow_logs module; Checkov cannot trace the conditional flow_vpc_ids expression through the module boundary.

  # When ipv4_ipam_pool_id is set, the CIDR is sourced from the IPAM pool and
  # cidr_block must be null; otherwise fall back to the static vpc_cidr.
  cidr_block          = var.ipv4_ipam_pool_id == null ? var.vpc_cidr : null
  ipv4_ipam_pool_id   = var.ipv4_ipam_pool_id
  ipv4_netmask_length = var.ipv4_netmask_length

  # IPv6 is fully opt-in via enable_ipv6. When enabled without an
  # ipv6_ipam_pool_id, request an Amazon-provided /56 (assign_generated_ipv6_cidr_block);
  # when an IPv6 IPAM pool is supplied, source the CIDR from it instead.
  # assign_generated_ipv6_cidr_block and ipv6_ipam_pool_id are mutually
  # exclusive at the provider level -- and the provider treats "explicitly
  # set to false/null-with-a-value" as "set" for conflict purposes, so the
  # inactive branch must resolve to null, not false, to avoid a
  # "Conflicting configuration arguments" plan error.
  assign_generated_ipv6_cidr_block = (var.enable_ipv6 && var.ipv6_ipam_pool_id == null) ? true : null
  ipv6_ipam_pool_id                = var.enable_ipv6 ? var.ipv6_ipam_pool_id : null
  ipv6_cidr_block                  = (var.enable_ipv6 && var.ipv6_ipam_pool_id != null) ? var.ipv6_cidr_block : null
  # ipv6_netmask_length conflicts with ipv6_cidr_block at the provider level
  # (they're alternate ways to size/select the CIDR from the pool), so only
  # pass it through when the caller hasn't also supplied an explicit
  # ipv6_cidr_block.
  ipv6_netmask_length                  = (var.enable_ipv6 && var.ipv6_ipam_pool_id != null && var.ipv6_cidr_block == null) ? var.ipv6_netmask_length : null
  ipv6_cidr_block_network_border_group = var.enable_ipv6 ? var.ipv6_cidr_block_network_border_group : null

  enable_dns_hostnames                 = var.enable_dns_hostnames
  enable_dns_support                   = var.enable_dns_support
  enable_network_address_usage_metrics = var.enable_network_address_usage_metrics
  instance_tenancy                     = var.instance_tenancy
  tags                                 = merge(tomap({ Name = var.name }), var.tags)

  lifecycle {
    # Every managed subnet needs a unique /64 out of the VPC's own IPv6
    # prefix; if the combined subnet count across all tiers exceeds the
    # number of /64 blocks the selected prefix can provide, the
    # cidrsubnet() calls on aws_subnet resources below fail with an opaque
    # "not enough remaining address space" error. Fail fast here instead
    # with a clear, specific message.
    precondition {
      condition = !var.enable_ipv6 || (
        length(var.private_subnets_list) + length(var.public_subnets_list) + length(var.dmz_subnets_list) +
        length(var.db_subnets_list) + length(var.mgmt_subnets_list) + length(var.workspaces_subnets_list)
      ) <= pow(2, local.ipv6_newbits)
      error_message = "The combined subnet count across all tiers (private+public+dmz+db+mgmt+workspaces) exceeds the number of /64 blocks available from the selected IPv6 prefix length (ipv6_netmask_length, or the prefix derived from an explicit ipv6_cidr_block). Use a larger prefix (smaller netmask number) or reduce the total subnet count."
    }
  }
}


###########################
# VPC Endpoints
###########################

# The bare security group is composed from modules/aws/security_group rather
# than declared inline (AGENTS.md module composition rule); its ingress/egress
# rules are then attached as standalone aws_vpc_security_group_ingress_rule /
# aws_vpc_security_group_egress_rule resources, which is the AWS provider's
# current recommended pattern over aws_security_group's inline ingress/egress
# blocks.
module "ssm_vpc_endpoint_sg" {
  source = "../security_group"

  name        = "${var.name}-vpc-endpoint-sg"
  description = "SSM/ECR/CloudWatch Logs VPC service endpoint SG."
  vpc_id      = aws_vpc.vpc.id
  tags        = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_https_tcp" {
  security_group_id = module.ssm_vpc_endpoint_sg.id
  description       = "VPC endpoint communication over HTTPS"
  # Reference the VPC's resolved CIDR so IPAM-sourced VPCs (where the CIDR is
  # not known until apply) work without requiring a separate vpc_cidr value.
  cidr_ipv4   = aws_vpc.vpc.cidr_block
  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
}

resource "aws_vpc_security_group_ingress_rule" "vpc_endpoint_https_udp" {
  security_group_id = module.ssm_vpc_endpoint_sg.id
  description       = "VPC endpoint communication over HTTPS"
  cidr_ipv4         = aws_vpc.vpc.cidr_block
  from_port         = 443
  to_port           = 443
  ip_protocol       = "udp"
}

resource "aws_vpc_security_group_egress_rule" "vpc_endpoint_all_traffic" {
  security_group_id = module.ssm_vpc_endpoint_sg.id
  description       = "All traffic"
  # Allow VPC endpoint outbound traffic to VPC endpoint
  #tfsec:ignore:aws-ec2-no-public-egress-sgr
  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}

# SSM VPC Endpoints
resource "aws_vpc_endpoint" "ec2messages" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ec2messages"
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "kms" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.kms"
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssm" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm"
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssm-contacts" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm-contacts"
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssm-incidents" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssm-incidents"
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = toset([for subnet_index in var.subnet_indices : aws_subnet.private_subnets[subnet_index].id])
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ssmmessages" {
  count               = var.enable_ssm_vpc_endpoints ? 1 : 0
  vpc_id              = aws_vpc.vpc.id
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ssmmessages"
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
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
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
  subnet_ids          = toset(aws_subnet.private_subnets[*].id)
  vpc_endpoint_type   = "Interface"
  vpc_id              = aws_vpc.vpc.id
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  count               = var.enable_ecr_vpc_endpoints ? 1 : 0
  private_dns_enabled = true
  service_name        = "com.amazonaws.${data.aws_region.current.region}.ecr.dkr"
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
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
  security_group_ids  = [module.ssm_vpc_endpoint_sg.id]
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

# Generic, caller-defined VPC endpoints. Use this (via var.vpc_endpoints) to
# attach any endpoint not covered by the enable_ssm_vpc_endpoints /
# enable_ecr_vpc_endpoints / enable_s3_endpoint shortcuts above, without
# editing this module.
resource "aws_vpc_endpoint" "custom" {
  for_each = var.vpc_endpoints

  vpc_id                     = aws_vpc.vpc.id
  service_name               = each.value.service_name
  resource_configuration_arn = each.value.resource_configuration_arn
  service_network_arn        = each.value.service_network_arn
  service_region             = each.value.service_region
  vpc_endpoint_type          = each.value.vpc_endpoint_type
  auto_accept                = each.value.auto_accept
  policy                     = each.value.policy
  private_dns_enabled        = each.value.private_dns_enabled
  ip_address_type            = each.value.ip_address_type
  security_group_ids         = length(each.value.security_group_ids) > 0 ? each.value.security_group_ids : null
  subnet_ids                 = each.value.subnet_ids
  # Gateway endpoints default to every public/private route table this
  # module manages unless the caller supplies explicit route_table_ids.
  route_table_ids = (
    each.value.vpc_endpoint_type == "Gateway" && each.value.route_table_ids == null
    ? concat(aws_route_table.public_route_table[*].id, aws_route_table.private_route_table[*].id)
    : each.value.route_table_ids
  )
  tags = merge(tomap({ Name = each.key }), var.tags, each.value.tags)

  dynamic "dns_options" {
    for_each = each.value.dns_options != null ? [each.value.dns_options] : []
    content {
      dns_record_ip_type                             = dns_options.value.dns_record_ip_type
      private_dns_only_for_inbound_resolver_endpoint = dns_options.value.private_dns_only_for_inbound_resolver_endpoint
      private_dns_preference                         = dns_options.value.private_dns_preference
      private_dns_specified_domains                  = dns_options.value.private_dns_specified_domains
    }
  }

  dynamic "subnet_configuration" {
    for_each = each.value.subnet_configuration
    content {
      ipv4      = subnet_configuration.value.ipv4
      ipv6      = subnet_configuration.value.ipv6
      subnet_id = subnet_configuration.value.subnet_id
    }
  }
}

###########################
# Subnets
###########################

resource "aws_subnet" "private_subnets" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = var.private_subnets_list[count.index]
  availability_zone               = element(var.azs, count.index)
  count                           = length(var.private_subnets_list)
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, local.ipv6_newbits, local.ipv6_private_offset + count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  tags                            = merge(var.tags, ({ "Name" = format("%s-subnet-private-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "public_subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.public_subnets_list[count.index]
  availability_zone = element(var.azs, count.index)
  # Allow public IP assignment for public subnets and zone
  #tfsec:ignore:aws-ec2-no-public-ip-subnet
  map_public_ip_on_launch         = var.map_public_ip_on_launch
  count                           = length(var.public_subnets_list)
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, local.ipv6_newbits, local.ipv6_public_offset + count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  tags                            = merge(var.tags, ({ "Name" = format("%s-subnet-public-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "dmz_subnets" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = var.dmz_subnets_list[count.index]
  availability_zone               = element(var.azs, count.index)
  count                           = length(var.dmz_subnets_list)
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, local.ipv6_newbits, local.ipv6_dmz_offset + count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  tags                            = merge(var.tags, ({ "Name" = format("%s-subnet-dmz-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "db_subnets" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = var.db_subnets_list[count.index]
  availability_zone               = element(var.azs, count.index)
  count                           = length(var.db_subnets_list)
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, local.ipv6_newbits, local.ipv6_db_offset + count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  tags                            = merge(var.tags, ({ "Name" = format("%s-subnet-db-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "mgmt_subnets" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = var.mgmt_subnets_list[count.index]
  availability_zone               = element(var.azs, count.index)
  count                           = length(var.mgmt_subnets_list)
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, local.ipv6_newbits, local.ipv6_mgmt_offset + count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  tags                            = merge(var.tags, ({ "Name" = format("%s-subnet-mgmt-%s", var.name, element(var.azs, count.index)) }))
}

resource "aws_subnet" "workspaces_subnets" {
  vpc_id                          = aws_vpc.vpc.id
  cidr_block                      = var.workspaces_subnets_list[count.index]
  availability_zone               = element(var.azs, count.index)
  count                           = length(var.workspaces_subnets_list)
  ipv6_cidr_block                 = var.enable_ipv6 ? cidrsubnet(aws_vpc.vpc.ipv6_cidr_block, local.ipv6_newbits, local.ipv6_workspaces_offset + count.index) : null
  assign_ipv6_address_on_creation = var.enable_ipv6
  tags                            = merge(var.tags, ({ "Name" = format("%s-subnet-workspaces-%s", var.name, element(var.azs, count.index)) }))
}

###########################
# Gateways
###########################

resource "aws_internet_gateway" "igw" {
  count  = local.enable_igw ? 1 : 0
  tags   = merge(var.tags, ({ "Name" = format("%s-igw", var.name) }))
  vpc_id = aws_vpc.vpc.id
}

# NAT gateways don't support IPv6 -- outbound-only IPv6 for the non-public
# tiers instead goes through an egress-only internet gateway.
resource "aws_egress_only_internet_gateway" "eigw" {
  count  = var.enable_ipv6 ? 1 : 0
  tags   = merge(var.tags, ({ "Name" = format("%s-eigw", var.name) }))
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

# The IGW already routes IPv6 once the VPC has an IPv6 CIDR, so the public
# tier's IPv6 default route also targets it (no separate resource needed).
resource "aws_route" "public_default_route_ipv6" {
  count                       = (local.enable_igw && var.enable_ipv6) ? 1 : 0
  destination_ipv6_cidr_block = "::/0"
  gateway_id                  = aws_internet_gateway.igw[0].id
  route_table_id              = aws_route_table.public_route_table[0].id
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

# NAT gateways don't support IPv6, so outbound-only IPv6 always targets the
# egress-only internet gateway regardless of enable_nat_gateway/enable_firewall.
# count/indexing must match the number of private route tables
# (length(var.private_subnets_list)), not length(var.azs) -- those two can
# differ (e.g. more subnets than AZs, now explicitly supported by
# subnet_indices), and using length(var.azs) would either skip a route table
# entirely or wrap via element() and attempt a duplicate ::/0 route on one.
resource "aws_route" "private_default_route_ipv6" {
  count                       = var.enable_ipv6 ? length(var.private_subnets_list) : 0
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw[0].id
  route_table_id              = aws_route_table.private_route_table[count.index].id
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

# count/indexing must match the number of db route tables (see the comment
# on aws_route.private_default_route_ipv6 above for why).
resource "aws_route" "db_default_route_ipv6" {
  count                       = var.enable_ipv6 ? length(var.db_subnets_list) : 0
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw[0].id
  route_table_id              = aws_route_table.db_route_table[count.index].id
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

# count/indexing must match the number of dmz route tables (see the comment
# on aws_route.private_default_route_ipv6 above for why).
resource "aws_route" "dmz_default_route_ipv6" {
  count                       = var.enable_ipv6 ? length(var.dmz_subnets_list) : 0
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw[0].id
  route_table_id              = aws_route_table.dmz_route_table[count.index].id
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

# count/indexing must match the number of mgmt route tables (see the comment
# on aws_route.private_default_route_ipv6 above for why).
resource "aws_route" "mgmt_default_route_ipv6" {
  count                       = var.enable_ipv6 ? length(var.mgmt_subnets_list) : 0
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw[0].id
  route_table_id              = aws_route_table.mgmt_route_table[count.index].id
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

# count/indexing must match the number of workspaces route tables (see the
# comment on aws_route.private_default_route_ipv6 above for why).
resource "aws_route" "workspaces_default_route_ipv6" {
  count                       = var.enable_ipv6 ? length(var.workspaces_subnets_list) : 0
  destination_ipv6_cidr_block = "::/0"
  egress_only_gateway_id      = aws_egress_only_internet_gateway.eigw[0].id
  route_table_id              = aws_route_table.workspaces_route_table[count.index].id
}

# Caller-defined additional routes (VPC peering, Transit Gateway, prefix
# lists, carrier gateway, etc.) fanned out across every route table this
# module manages in the tier(s) each route's route_table_types selects.
resource "aws_route" "additional" {
  for_each = local.additional_routes_by_key

  route_table_id              = each.value.route_table_id
  destination_cidr_block      = each.value.route.destination_cidr_block
  destination_ipv6_cidr_block = each.value.route.destination_ipv6_cidr_block
  destination_prefix_list_id  = each.value.route.destination_prefix_list_id
  vpc_peering_connection_id   = each.value.route.vpc_peering_connection_id
  transit_gateway_id          = each.value.route.transit_gateway_id
  carrier_gateway_id          = each.value.route.carrier_gateway_id
  core_network_arn            = each.value.route.core_network_arn
  vpc_endpoint_id             = each.value.route.vpc_endpoint_id
  network_interface_id        = each.value.route.network_interface_id
  egress_only_gateway_id      = each.value.route.egress_only_gateway_id
  nat_gateway_id              = each.value.route.nat_gateway_id
  gateway_id                  = each.value.route.gateway_id
  local_gateway_id            = each.value.route.local_gateway_id
  odb_network_arn             = each.value.route.odb_network_arn
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

  count = var.enable_flow_logs ? 1 : 0

  # CloudWatch Log Group
  cloudwatch_name_prefix                 = var.cloudwatch_name_prefix
  cloudwatch_retention_in_days           = var.cloudwatch_retention_in_days
  cloudwatch_deletion_protection_enabled = var.cloudwatch_deletion_protection_enabled

  # IAM Policy
  iam_policy_description = var.iam_policy_description
  iam_policy_name_prefix = var.iam_policy_name_prefix
  iam_policy_path        = var.iam_policy_path

  # IAM Role
  iam_role_assume_role_policy    = var.iam_role_assume_role_policy
  iam_role_description           = var.iam_role_description
  iam_role_force_detach_policies = var.iam_role_force_detach_policies
  iam_role_max_session_duration  = var.iam_role_max_session_duration
  iam_role_name_prefix           = var.iam_role_name_prefix
  iam_role_permissions_boundary  = var.iam_role_permissions_boundary

  # KMS Encryption Key
  key_customer_master_key_spec = var.key_customer_master_key_spec
  key_description              = var.key_description
  key_deletion_window_in_days  = var.key_deletion_window_in_days
  key_enable_key_rotation      = var.key_enable_key_rotation
  key_usage                    = var.key_usage
  key_is_enabled               = var.key_is_enabled
  key_name_prefix              = var.key_name_prefix

  # Flow Log
  #
  # modules/aws/flow_logs enforces exactly one non-null target list
  # (flow_eni_ids/flow_subnet_ids/flow_transit_gateway_ids/
  # flow_transit_gateway_attachment_ids/flow_vpc_ids). This module's default
  # target is its own VPC, but if the caller supplies any of the four
  # alternate target variables, flow_vpc_ids must resolve to null instead of
  # always being set -- otherwise the child module's precondition rejects
  # the plan (two non-null targets) any time an alternate target is used.
  flow_deliver_cross_account_role     = var.flow_deliver_cross_account_role
  flow_eni_ids                        = var.flow_eni_ids
  flow_log_destination_type           = var.flow_log_destination_type
  flow_log_format                     = var.flow_log_format
  flow_max_aggregation_interval       = var.flow_max_aggregation_interval
  flow_subnet_ids                     = var.flow_subnet_ids
  flow_traffic_type                   = var.flow_traffic_type
  flow_transit_gateway_ids            = var.flow_transit_gateway_ids
  flow_transit_gateway_attachment_ids = var.flow_transit_gateway_attachment_ids
  flow_vpc_ids = (
    var.flow_eni_ids == null &&
    var.flow_subnet_ids == null &&
    var.flow_transit_gateway_ids == null &&
    var.flow_transit_gateway_attachment_ids == null
  ) ? [aws_vpc.vpc.id] : null

  tags = var.tags
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
}
