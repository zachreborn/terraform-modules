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
# Data Sources
###########################

data "aws_caller_identity" "current" {}

###########################
# Locals
###########################

locals {
  # Resolve the KMS key ARN used to encrypt the file system: either the key
  # created by this module or a caller-supplied key.
  kms_key_arn = var.create_kms_key ? module.kms_key[0].arn : var.kms_key_id
}

###########################
# KMS Encryption Key
###########################

module "kms_key" {
  count  = var.create_kms_key ? 1 : 0
  source = "../kms"

  deletion_window_in_days = var.kms_key_deletion_window_in_days
  description             = var.kms_key_description
  enable_key_rotation     = var.kms_key_enable_key_rotation
  name_prefix             = var.kms_key_name_prefix
  tags                    = merge(tomap({ Name = "${var.name}-kms" }), var.tags)
  # Matches the ../transfer_family composition pattern: FSx does not require a
  # service-principal statement to use the key. FSx creates its own KMS grants
  # on your behalf using the kms:CreateGrant permission delegated to the caller
  # via the account-root statement below, so only the "Enable IAM User
  # Permissions" statement is needed here.
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "Enable IAM User Permissions",
        "Effect" = "Allow",
        "Principal" = {
          "AWS" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action"   = "kms:*",
        "Resource" = "*"
      }
    ]
  })
}

###########################
# FSx ONTAP File System
###########################

resource "aws_fsx_ontap_file_system" "this" {
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  deployment_type                   = var.deployment_type
  endpoint_ip_address_range         = var.endpoint_ip_address_range
  fsx_admin_password                = var.fsx_admin_password
  ha_pairs                          = var.ha_pairs
  kms_key_id                        = local.kms_key_arn
  preferred_subnet_id               = var.preferred_subnet_id
  route_table_ids                   = var.route_table_ids
  security_group_ids                = var.security_group_ids
  storage_capacity                  = var.storage_capacity
  storage_type                      = var.storage_type
  subnet_ids                        = var.subnet_ids
  tags                              = merge(tomap({ Name = var.name }), var.tags)
  throughput_capacity               = var.throughput_capacity
  throughput_capacity_per_ha_pair   = var.throughput_capacity_per_ha_pair
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  dynamic "disk_iops_configuration" {
    for_each = var.disk_iops_configuration != null ? [var.disk_iops_configuration] : []
    content {
      iops = disk_iops_configuration.value.iops
      mode = disk_iops_configuration.value.mode
    }
  }

  lifecycle {
    precondition {
      condition     = var.create_kms_key || var.kms_key_id != null
      error_message = "kms_key_id is required when create_kms_key is false."
    }

    precondition {
      condition     = (var.throughput_capacity != null) != (var.throughput_capacity_per_ha_pair != null)
      error_message = "Exactly one of throughput_capacity or throughput_capacity_per_ha_pair must be set."
    }

    precondition {
      condition     = !startswith(var.deployment_type, "MULTI_AZ") || length(var.subnet_ids) == 2
      error_message = "MULTI_AZ deployment types require exactly two subnet_ids."
    }

    precondition {
      condition     = startswith(var.deployment_type, "MULTI_AZ") || length(var.subnet_ids) == 1
      error_message = "SINGLE_AZ deployment types require exactly one subnet_id."
    }
  }
}

###########################
# Storage Virtual Machines
###########################

resource "aws_fsx_ontap_storage_virtual_machine" "this" {
  for_each = var.storage_virtual_machines

  file_system_id             = aws_fsx_ontap_file_system.this.id
  name                       = coalesce(each.value.name, each.key)
  root_volume_security_style = each.value.root_volume_security_style
  svm_admin_password         = each.value.svm_admin_password
  tags                       = merge(tomap({ Name = coalesce(each.value.name, each.key) }), var.tags)

  dynamic "active_directory_configuration" {
    for_each = each.value.active_directory_configuration != null ? [each.value.active_directory_configuration] : []
    content {
      netbios_name = active_directory_configuration.value.netbios_name
      self_managed_active_directory_configuration {
        dns_ips                                = active_directory_configuration.value.self_managed_active_directory_configuration.dns_ips
        domain_name                            = active_directory_configuration.value.self_managed_active_directory_configuration.domain_name
        file_system_administrators_group       = active_directory_configuration.value.self_managed_active_directory_configuration.file_system_administrators_group
        organizational_unit_distinguished_name = active_directory_configuration.value.self_managed_active_directory_configuration.organizational_unit_distinguished_name
        password                               = active_directory_configuration.value.self_managed_active_directory_configuration.password
        username                               = active_directory_configuration.value.self_managed_active_directory_configuration.username
      }
    }
  }
}

###########################
# Volumes
###########################

resource "aws_fsx_ontap_volume" "this" {
  for_each = var.volumes

  bypass_snaplock_enterprise_retention = each.value.bypass_snaplock_enterprise_retention
  copy_tags_to_backups                 = each.value.copy_tags_to_backups
  final_backup_tags                    = each.value.final_backup_tags
  junction_path                        = each.value.junction_path
  name                                 = coalesce(each.value.name, each.key)
  ontap_volume_type                    = each.value.ontap_volume_type
  security_style                       = each.value.security_style
  size_in_bytes                        = each.value.size_in_bytes
  size_in_megabytes                    = each.value.size_in_megabytes
  skip_final_backup                    = each.value.skip_final_backup
  snapshot_policy                      = each.value.snapshot_policy
  storage_efficiency_enabled           = each.value.storage_efficiency_enabled
  storage_virtual_machine_id           = aws_fsx_ontap_storage_virtual_machine.this[each.value.storage_virtual_machine_key].id
  tags                                 = merge(tomap({ Name = coalesce(each.value.name, each.key) }), var.tags)
  volume_style                         = each.value.volume_style
  volume_type                          = each.value.volume_type

  dynamic "aggregate_configuration" {
    for_each = each.value.aggregate_configuration != null ? [each.value.aggregate_configuration] : []
    content {
      aggregates                 = aggregate_configuration.value.aggregates
      constituents_per_aggregate = aggregate_configuration.value.constituents_per_aggregate
    }
  }

  dynamic "snaplock_configuration" {
    for_each = each.value.snaplock_configuration != null ? [each.value.snaplock_configuration] : []
    content {
      audit_log_volume           = snaplock_configuration.value.audit_log_volume
      privileged_delete          = snaplock_configuration.value.privileged_delete
      snaplock_type              = snaplock_configuration.value.snaplock_type
      volume_append_mode_enabled = snaplock_configuration.value.volume_append_mode_enabled

      dynamic "autocommit_period" {
        for_each = snaplock_configuration.value.autocommit_period != null ? [snaplock_configuration.value.autocommit_period] : []
        content {
          type  = autocommit_period.value.type
          value = autocommit_period.value.value
        }
      }

      dynamic "retention_period" {
        for_each = snaplock_configuration.value.retention_period != null ? [snaplock_configuration.value.retention_period] : []
        content {
          dynamic "default_retention" {
            for_each = retention_period.value.default_retention != null ? [retention_period.value.default_retention] : []
            content {
              type  = default_retention.value.type
              value = default_retention.value.value
            }
          }

          dynamic "maximum_retention" {
            for_each = retention_period.value.maximum_retention != null ? [retention_period.value.maximum_retention] : []
            content {
              type  = maximum_retention.value.type
              value = maximum_retention.value.value
            }
          }

          dynamic "minimum_retention" {
            for_each = retention_period.value.minimum_retention != null ? [retention_period.value.minimum_retention] : []
            content {
              type  = minimum_retention.value.type
              value = minimum_retention.value.value
            }
          }
        }
      }
    }
  }

  dynamic "tiering_policy" {
    for_each = each.value.tiering_policy != null ? [each.value.tiering_policy] : []
    content {
      cooling_period = tiering_policy.value.cooling_period
      name           = tiering_policy.value.name
    }
  }
}
