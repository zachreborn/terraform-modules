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
data "aws_region" "current" {}

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
  tags                    = var.tags
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
      },
      {
        "Sid"    = "Allow Amazon FSx to use the key",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "fsx.${data.aws_region.current.region}.amazonaws.com"
        },
        "Action" = [
          "kms:CreateGrant",
          "kms:Decrypt*",
          "kms:DescribeKey",
          "kms:Encrypt*",
          "kms:GenerateDataKey*",
          "kms:ListGrants",
          "kms:ReEncrypt*"
        ],
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
  junction_path                        = each.value.junction_path
  name                                 = coalesce(each.value.name, each.key)
  ontap_volume_type                    = each.value.ontap_volume_type
  security_style                       = each.value.security_style
  size_in_megabytes                    = each.value.size_in_megabytes
  skip_final_backup                    = each.value.skip_final_backup
  snapshot_policy                      = each.value.snapshot_policy
  storage_efficiency_enabled           = each.value.storage_efficiency_enabled
  storage_virtual_machine_id           = aws_fsx_ontap_storage_virtual_machine.this[each.value.storage_virtual_machine_key].id
  tags                                 = merge(tomap({ Name = coalesce(each.value.name, each.key) }), var.tags)

  dynamic "tiering_policy" {
    for_each = each.value.tiering_policy != null ? [each.value.tiering_policy] : []
    content {
      cooling_period = tiering_policy.value.cooling_period
      name           = tiering_policy.value.name
    }
  }
}
