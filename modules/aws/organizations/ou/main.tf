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
  # Bucket each entry by how many parent_key hops are required to reach an entry
  # that sets a literal parent_id. Terraform cannot let one instance of a
  # for_each resource reference a sibling instance of the same resource block,
  # so nested OUs are declared as separate resources per level, each one
  # referencing the previous level's resource block.
  ou_level_0 = { for k, v in var.organizational_units : k => v if v.parent_key == null }
  ou_level_1 = { for k, v in var.organizational_units : k => v if v.parent_key != null && contains(keys(local.ou_level_0), v.parent_key) }
  ou_level_2 = { for k, v in var.organizational_units : k => v if v.parent_key != null && contains(keys(local.ou_level_1), v.parent_key) }
  ou_level_3 = { for k, v in var.organizational_units : k => v if v.parent_key != null && contains(keys(local.ou_level_2), v.parent_key) }

  all_organizational_units = merge(
    aws_organizations_organizational_unit.level_0,
    aws_organizations_organizational_unit.level_1,
    aws_organizations_organizational_unit.level_2,
    aws_organizations_organizational_unit.level_3,
  )
}

###########################
# Organizational Units
###########################

# Level 0 — top-level OUs whose parent is a literal Root or OU ID.
resource "aws_organizations_organizational_unit" "level_0" {
  for_each = local.ou_level_0

  name      = coalesce(each.value.name, each.key)
  parent_id = each.value.parent_id
  tags      = merge(var.tags, each.value.tags)

  lifecycle {
    create_before_destroy = true
  }
}

# Level 1 — OUs nested under a level 0 OU.
resource "aws_organizations_organizational_unit" "level_1" {
  for_each = local.ou_level_1

  name      = coalesce(each.value.name, each.key)
  parent_id = aws_organizations_organizational_unit.level_0[each.value.parent_key].id
  tags      = merge(var.tags, each.value.tags)

  lifecycle {
    create_before_destroy = true
  }
}

# Level 2 — OUs nested under a level 1 OU.
resource "aws_organizations_organizational_unit" "level_2" {
  for_each = local.ou_level_2

  name      = coalesce(each.value.name, each.key)
  parent_id = aws_organizations_organizational_unit.level_1[each.value.parent_key].id
  tags      = merge(var.tags, each.value.tags)

  lifecycle {
    create_before_destroy = true
  }
}

# Level 3 — OUs nested under a level 2 OU.
resource "aws_organizations_organizational_unit" "level_3" {
  for_each = local.ou_level_3

  name      = coalesce(each.value.name, each.key)
  parent_id = aws_organizations_organizational_unit.level_2[each.value.parent_key].id
  tags      = merge(var.tags, each.value.tags)

  lifecycle {
    create_before_destroy = true
  }
}
