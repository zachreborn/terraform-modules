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
  # Resolve the KMS key ARN used to encrypt the gateway log group: either the
  # key created by this module or a caller-supplied key.
  kms_key_arn = var.create_cloudwatch_log_group && var.create_kms_key ? module.kms_key[0].arn : var.kms_key_id

  # Resolve the CloudWatch log group ARN wired to the gateway: a caller-supplied
  # ARN takes precedence over one created by this module.
  cloudwatch_log_group_arn = var.cloudwatch_log_group_arn != null ? var.cloudwatch_log_group_arn : (var.create_cloudwatch_log_group ? module.cloudwatch_log_group[0].arn : null)
}

###########################
# KMS Encryption Key
###########################

module "kms_key" {
  count  = var.create_cloudwatch_log_group && var.create_kms_key ? 1 : 0
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

module "cloudwatch_log_group" {
  count  = var.create_cloudwatch_log_group && var.cloudwatch_log_group_arn == null ? 1 : 0
  source = "../cloudwatch/log_group"

  kms_key_id        = local.kms_key_arn
  name_prefix       = var.cloudwatch_name_prefix
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = var.tags
}

###########################
# Storage Gateway
###########################

resource "aws_storagegateway_gateway" "this" {
  activation_key                              = var.activation_key
  average_download_rate_limit_in_bits_per_sec = var.average_download_rate_limit_in_bits_per_sec
  average_upload_rate_limit_in_bits_per_sec   = var.average_upload_rate_limit_in_bits_per_sec
  cloudwatch_log_group_arn                    = local.cloudwatch_log_group_arn
  gateway_ip_address                          = var.gateway_ip_address
  gateway_name                                = var.gateway_name
  gateway_timezone                            = var.gateway_timezone
  gateway_type                                = var.gateway_type
  gateway_vpc_endpoint                        = var.gateway_vpc_endpoint
  smb_file_share_visibility                   = var.smb_file_share_visibility
  smb_guest_password                          = var.smb_guest_password
  smb_security_strategy                       = var.smb_security_strategy
  tags                                        = merge(tomap({ Name = var.gateway_name }), var.tags)

  dynamic "maintenance_start_time" {
    for_each = var.maintenance_start_time != null ? [var.maintenance_start_time] : []
    content {
      day_of_month   = maintenance_start_time.value.day_of_month
      day_of_week    = maintenance_start_time.value.day_of_week
      hour_of_day    = maintenance_start_time.value.hour_of_day
      minute_of_hour = maintenance_start_time.value.minute_of_hour
    }
  }

  dynamic "smb_active_directory_settings" {
    for_each = var.smb_active_directory_settings != null ? [var.smb_active_directory_settings] : []
    content {
      domain_controllers  = smb_active_directory_settings.value.domain_controllers
      domain_name         = smb_active_directory_settings.value.domain_name
      organizational_unit = smb_active_directory_settings.value.organizational_unit
      password            = smb_active_directory_settings.value.password
      timeout_in_seconds  = smb_active_directory_settings.value.timeout_in_seconds
      username            = smb_active_directory_settings.value.username
    }
  }
}

###########################
# Cache Disks
###########################

resource "aws_storagegateway_cache" "this" {
  for_each = var.cache_disk_ids

  disk_id     = each.value
  gateway_arn = aws_storagegateway_gateway.this.arn
}

###########################
# File System Associations
###########################

resource "aws_storagegateway_file_system_association" "this" {
  for_each = var.file_system_associations

  audit_destination_arn = each.value.audit_destination_arn
  gateway_arn           = aws_storagegateway_gateway.this.arn
  location_arn          = each.value.location_arn
  password              = each.value.password
  tags                  = merge(tomap({ Name = each.key }), var.tags)
  username              = each.value.username

  dynamic "cache_attributes" {
    for_each = each.value.cache_attributes != null ? [each.value.cache_attributes] : []
    content {
      cache_stale_timeout_in_seconds = cache_attributes.value.cache_stale_timeout_in_seconds
    }
  }
}
