###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0: the `templates` map input uses optional() attributes in an object
  # type constraint, which were introduced in Terraform 1.3 / OpenTofu 1.6.
  required_version = ">= 1.3.0"
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
  # Resolve the per-template defaults that cannot be expressed as a static
  # optional() default because they depend on either the map key or on another
  # attribute of the same entry.
  templates = {
    for key, template in var.templates : key => merge(template, {
      # The provider requires ebs_encryption on every template. Default it to
      # DEFAULT (the account's default EBS encryption key) and switch to CUSTOM
      # automatically as soon as the caller supplies a customer managed key, so
      # staging disks and snapshots are always encrypted without the caller
      # having to keep the two attributes in sync by hand.
      ebs_encryption = (
        template.ebs_encryption != null
        ? template.ebs_encryption
        : (template.ebs_encryption_key_arn != null ? "CUSTOM" : "DEFAULT")
      )

      # staging_area_tags is required by the provider. Default it to the repo's
      # standard Name + tags merge so every EC2 replication server, EBS volume
      # and EBS snapshot created in the staging area is attributable.
      staging_area_tags = (
        template.staging_area_tags != null
        ? template.staging_area_tags
        : merge(tomap({ Name = coalesce(template.name, key) }), var.tags)
      )

      tags = (
        template.tags != null
        ? template.tags
        : merge(tomap({ Name = coalesce(template.name, key) }), var.tags)
      )
    })
  }
}

###########################
# Replication Configuration Templates
###########################

resource "aws_drs_replication_configuration_template" "this" {
  for_each = local.templates

  associate_default_security_group        = each.value.associate_default_security_group
  auto_replicate_new_disks                = each.value.auto_replicate_new_disks
  bandwidth_throttling                    = each.value.bandwidth_throttling
  create_public_ip                        = each.value.create_public_ip
  data_plane_routing                      = each.value.data_plane_routing
  default_large_staging_disk_type         = each.value.default_large_staging_disk_type
  ebs_encryption                          = each.value.ebs_encryption
  ebs_encryption_key_arn                  = each.value.ebs_encryption_key_arn
  region                                  = each.value.region
  replication_server_instance_type        = each.value.replication_server_instance_type
  replication_servers_security_groups_ids = each.value.replication_servers_security_groups_ids
  staging_area_subnet_id                  = each.value.staging_area_subnet_id
  staging_area_tags                       = each.value.staging_area_tags
  tags                                    = each.value.tags
  use_dedicated_replication_server        = each.value.use_dedicated_replication_server

  dynamic "pit_policy" {
    for_each = each.value.pit_policy
    content {
      enabled            = pit_policy.value.enabled
      interval           = pit_policy.value.interval
      retention_duration = pit_policy.value.retention_duration
      rule_id            = pit_policy.value.rule_id
      units              = pit_policy.value.units
    }
  }

  dynamic "timeouts" {
    for_each = each.value.timeouts != null ? [each.value.timeouts] : []
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }
}
