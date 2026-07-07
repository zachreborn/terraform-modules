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
  # Resolve the KMS key ARN used to encrypt the file system and (optionally) the
  # audit log group: either the key created by this module or a caller-supplied key.
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
  # Permissions" and CloudWatch Logs statements are needed here.
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
        "Sid"    = "Allow CloudWatch Logs to use the key",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "logs.${data.aws_region.current.region}.amazonaws.com"
        },
        "Action" = [
          "kms:Decrypt*",
          "kms:Describe*",
          "kms:Encrypt*",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ],
        "Resource" = "*",
        "Condition" = {
          "ArnEquals" = {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })
}

###########################
# CloudWatch Log Group
###########################

module "audit_log_group" {
  count  = var.enable_audit_logs ? 1 : 0
  source = "../cloudwatch/log_group"

  kms_key_id        = local.kms_key_arn
  name_prefix       = var.cloudwatch_name_prefix
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = merge(tomap({ Name = "${var.name}-audit-logs" }), var.tags)
}

###########################
# FSx Windows File System
###########################

resource "aws_fsx_windows_file_system" "this" {
  active_directory_id               = var.active_directory_id
  aliases                           = var.aliases
  automatic_backup_retention_days   = var.automatic_backup_retention_days
  backup_id                         = var.backup_id
  copy_tags_to_backups              = var.copy_tags_to_backups
  daily_automatic_backup_start_time = var.daily_automatic_backup_start_time
  deployment_type                   = var.deployment_type
  final_backup_tags                 = var.final_backup_tags
  kms_key_id                        = local.kms_key_arn
  preferred_subnet_id               = var.preferred_subnet_id
  security_group_ids                = var.security_group_ids
  skip_final_backup                 = var.skip_final_backup
  storage_capacity                  = var.storage_capacity
  storage_type                      = var.storage_type
  subnet_ids                        = var.subnet_ids
  tags                              = merge(tomap({ Name = var.name }), var.tags)
  throughput_capacity               = var.throughput_capacity
  weekly_maintenance_start_time     = var.weekly_maintenance_start_time

  dynamic "audit_log_configuration" {
    for_each = var.enable_audit_logs ? [1] : []
    content {
      audit_log_destination             = module.audit_log_group[0].arn
      file_access_audit_log_level       = var.file_access_audit_log_level
      file_share_access_audit_log_level = var.file_share_access_audit_log_level
    }
  }

  dynamic "disk_iops_configuration" {
    for_each = var.disk_iops_configuration != null ? [var.disk_iops_configuration] : []
    content {
      iops = disk_iops_configuration.value.iops
      mode = disk_iops_configuration.value.mode
    }
  }

  dynamic "self_managed_active_directory" {
    for_each = var.self_managed_active_directory != null ? [var.self_managed_active_directory] : []
    content {
      dns_ips                                = self_managed_active_directory.value.dns_ips
      domain_name                            = self_managed_active_directory.value.domain_name
      domain_join_service_account_secret     = self_managed_active_directory.value.domain_join_service_account_secret
      file_system_administrators_group       = self_managed_active_directory.value.file_system_administrators_group
      organizational_unit_distinguished_name = self_managed_active_directory.value.organizational_unit_distinguished_name
      password                               = self_managed_active_directory.value.password
      password_wo                            = self_managed_active_directory.value.password_wo
      password_wo_version                    = self_managed_active_directory.value.password_wo_version
      username                               = self_managed_active_directory.value.username
    }
  }

  lifecycle {
    precondition {
      condition     = (var.active_directory_id != null) != (var.self_managed_active_directory != null)
      error_message = "Exactly one of active_directory_id or self_managed_active_directory must be set."
    }

    precondition {
      condition     = var.create_kms_key || var.kms_key_id != null
      error_message = "kms_key_id is required when create_kms_key is false."
    }

    precondition {
      condition     = var.storage_type != "HDD" || var.storage_capacity >= 2000
      error_message = "storage_capacity must be at least 2000 GiB when storage_type is HDD."
    }

    precondition {
      condition     = var.deployment_type != "MULTI_AZ_1" || (length(var.subnet_ids) == 2 && var.preferred_subnet_id != null)
      error_message = "MULTI_AZ_1 deployment_type requires exactly two subnet_ids and preferred_subnet_id to be set."
    }

    precondition {
      condition     = var.deployment_type == "MULTI_AZ_1" || length(var.subnet_ids) == 1
      error_message = "SINGLE_AZ deployment types require exactly one subnet_id."
    }
  }
}
