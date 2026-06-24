###########################
# Provider Configuration
###########################
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
# Locals
###########################

locals {
  # Scopes available for pools to reference by key. The default private and
  # public scopes always exist on the IPAM; the enable_*_default_scope gates
  # control whether pools may resolve them via "private"/"public" keys.
  default_scopes = merge(
    var.enable_private_default_scope ? { private = aws_vpc_ipam.this.private_default_scope_id } : {},
    var.enable_public_default_scope ? { public = aws_vpc_ipam.this.public_default_scope_id } : {},
  )
  additional_scope_ids = { for key, scope in aws_vpc_ipam_scope.additional : key => scope.id }
  scope_ids            = merge(local.default_scopes, local.additional_scope_ids)

  # Pools are created in depth tiers so that a child pool can reference its
  # parent's ID without a single-resource self-reference (which OpenTofu/
  # Terraform reject as a dependency cycle). Nesting is supported up to three
  # levels (validated in variables.tf).
  pools_level_0 = { for key, pool in var.pools : key => pool if pool.parent_pool_key == null }
  pools_level_1 = { for key, pool in var.pools : key => pool if pool.parent_pool_key != null && contains(keys(local.pools_level_0), pool.parent_pool_key) }
  pools_level_2 = { for key, pool in var.pools : key => pool if pool.parent_pool_key != null && contains(keys(local.pools_level_1), pool.parent_pool_key) }

  # All created pools keyed by logical name, regardless of tier.
  all_pools = merge(
    aws_vpc_ipam_pool.level_0,
    aws_vpc_ipam_pool.level_1,
    aws_vpc_ipam_pool.level_2,
  )

  # Flatten (pool_key, cidr) pairs from each pool's provisioned_cidrs.
  pool_provisioned_cidrs = merge([
    for pool_key, pool in var.pools : {
      for cidr in pool.provisioned_cidrs :
      "${pool_key}:${cidr}" => {
        pool_key = pool_key
        cidr     = cidr
      }
    }
  ]...)

  # RAM share definitions. When sharing org-wide, principal is null so the ram
  # module defaults the association to the organization ARN. Otherwise one share
  # is created per (pool, principal) pair.
  ram_shares = var.share_with_organization ? {
    for pool_key in var.ram_share_pool_keys :
    "${pool_key}-org" => {
      pool_key  = pool_key
      principal = null
      name      = "${var.name}-ipam-${pool_key}"
    }
    } : merge([
      for pool_key in var.ram_share_pool_keys : {
        for idx, principal in var.ram_principals :
        "${pool_key}-${idx}" => {
          pool_key  = pool_key
          principal = principal
          name      = "${var.name}-ipam-${pool_key}-${idx}"
        }
      }
  ]...)
}

###########################
# IPAM
###########################

resource "aws_vpc_ipam" "this" {
  description        = var.description
  tier               = var.tier
  enable_private_gua = var.enable_private_gua
  metered_account    = var.metered_account
  cascade            = var.cascade

  dynamic "operating_regions" {
    for_each = toset(var.operating_regions)
    content {
      region_name = operating_regions.value
    }
  }

  tags = merge(tomap({ Name = var.name }), var.tags)
}

###########################
# Scopes
###########################

resource "aws_vpc_ipam_scope" "additional" {
  for_each = var.additional_private_scopes

  ipam_id     = aws_vpc_ipam.this.id
  description = each.value.description
  tags        = merge(tomap({ Name = "${var.name}-${each.key}" }), var.tags)
}

###########################
# Pools
###########################

# Level 0 — top-level pools (no parent).
resource "aws_vpc_ipam_pool" "level_0" {
  for_each = local.pools_level_0

  address_family                    = each.value.address_family
  ipam_scope_id                     = local.scope_ids[coalesce(each.value.scope_key, "private")]
  locale                            = each.value.locale
  description                       = each.value.description
  allocation_default_netmask_length = each.value.allocation_default_netmask_length
  allocation_min_netmask_length     = each.value.allocation_min_netmask_length
  allocation_max_netmask_length     = each.value.allocation_max_netmask_length
  allocation_resource_tags          = each.value.allocation_resource_tags
  auto_import                       = each.value.auto_import
  aws_service                       = each.value.aws_service
  public_ip_source                  = each.value.public_ip_source
  publicly_advertisable             = each.value.publicly_advertisable
  cascade                           = each.value.cascade
  tags                              = merge(tomap({ Name = "${var.name}-${each.key}" }), var.tags, each.value.tags)
}

# Level 1 — child pools whose parent is a level 0 pool.
resource "aws_vpc_ipam_pool" "level_1" {
  for_each = local.pools_level_1

  source_ipam_pool_id               = aws_vpc_ipam_pool.level_0[each.value.parent_pool_key].id
  address_family                    = each.value.address_family
  ipam_scope_id                     = local.scope_ids[coalesce(each.value.scope_key, "private")]
  locale                            = each.value.locale
  description                       = each.value.description
  allocation_default_netmask_length = each.value.allocation_default_netmask_length
  allocation_min_netmask_length     = each.value.allocation_min_netmask_length
  allocation_max_netmask_length     = each.value.allocation_max_netmask_length
  allocation_resource_tags          = each.value.allocation_resource_tags
  auto_import                       = each.value.auto_import
  aws_service                       = each.value.aws_service
  public_ip_source                  = each.value.public_ip_source
  publicly_advertisable             = each.value.publicly_advertisable
  cascade                           = each.value.cascade
  tags                              = merge(tomap({ Name = "${var.name}-${each.key}" }), var.tags, each.value.tags)
}

# Level 2 — grandchild pools whose parent is a level 1 pool.
resource "aws_vpc_ipam_pool" "level_2" {
  for_each = local.pools_level_2

  source_ipam_pool_id               = aws_vpc_ipam_pool.level_1[each.value.parent_pool_key].id
  address_family                    = each.value.address_family
  ipam_scope_id                     = local.scope_ids[coalesce(each.value.scope_key, "private")]
  locale                            = each.value.locale
  description                       = each.value.description
  allocation_default_netmask_length = each.value.allocation_default_netmask_length
  allocation_min_netmask_length     = each.value.allocation_min_netmask_length
  allocation_max_netmask_length     = each.value.allocation_max_netmask_length
  allocation_resource_tags          = each.value.allocation_resource_tags
  auto_import                       = each.value.auto_import
  aws_service                       = each.value.aws_service
  public_ip_source                  = each.value.public_ip_source
  publicly_advertisable             = each.value.publicly_advertisable
  cascade                           = each.value.cascade
  tags                              = merge(tomap({ Name = "${var.name}-${each.key}" }), var.tags, each.value.tags)
}

###########################
# Pool CIDRs
###########################

resource "aws_vpc_ipam_pool_cidr" "this" {
  for_each = local.pool_provisioned_cidrs

  ipam_pool_id = local.all_pools[each.value.pool_key].id
  cidr         = each.value.cidr
}

###########################
# Allocations
###########################

resource "aws_vpc_ipam_pool_cidr_allocation" "this" {
  for_each = var.allocations

  ipam_pool_id     = local.all_pools[each.value.pool_key].id
  cidr             = each.value.cidr
  netmask_length   = each.value.netmask_length
  description      = each.value.description
  disallowed_cidrs = each.value.disallowed_cidrs
}

###########################
# Organization Delegated Admin
###########################

# Registers the IPAM delegated administrator for the organization. Must be
# applied from the Organization management account.
resource "aws_vpc_ipam_organization_admin_account" "this" {
  count = var.delegated_admin_account_id != null ? 1 : 0

  delegated_admin_account_id = var.delegated_admin_account_id
}

###########################
# RAM Sharing
###########################

# Cross-account/organization sharing of IPAM pools is performed by composing the
# modules/aws/ram module (per the "no inline cross-cutting resources" rule in
# AGENTS.md) rather than declaring aws_ram_* resources here.
module "ram" {
  source   = "../ram"
  for_each = local.ram_shares

  name                      = each.value.name
  resource_arn              = local.all_pools[each.value.pool_key].arn
  principal                 = each.value.principal
  allow_external_principals = false
  tags                      = var.tags
}
