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
data "aws_partition" "current" {}
data "aws_region" "current" {}

# Key policy applied to the CMK created for exec-command logging and managed
# storage encryption. Grants the account root full administrative access and
# allows the regional CloudWatch Logs service principal to use the key so the
# encrypted exec-command log group works out of the box.
data "aws_iam_policy_document" "kms" {
  count = var.create_kms_key ? 1 : 0

  statement {
    sid       = "EnableRootAccount"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:${data.aws_partition.current.partition}:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid    = "AllowCloudWatchLogs"
    effect = "Allow"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*",
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current.region}.amazonaws.com"]
    }
  }
}

###########################
# Locals
###########################

locals {
  # The setting blocks always include containerInsights plus any caller-supplied
  # additional settings.
  cluster_settings = concat(
    [{ name = "containerInsights", value = var.container_insights }],
    var.additional_settings,
  )

  # Effective KMS key ARN for exec-command logging encryption.
  kms_key_arn = var.create_kms_key ? module.kms[0].arn : var.kms_key_arn

  # Effective KMS key ARN for Fargate managed (ephemeral) storage encryption.
  # Defaults to the created CMK when one is created.
  managed_storage_kms_key_arn = coalesce(
    var.managed_storage_kms_key_arn,
    var.create_kms_key ? module.kms[0].arn : null,
  )

  # Effective exec-command CloudWatch log group name.
  cloud_watch_log_group_name = var.create_cloud_watch_log_group ? module.log_group[0].name : var.cloud_watch_log_group_name

  create_log_group = var.enable_execute_command_logging && var.create_cloud_watch_log_group
}

###########################
# KMS Key (composition)
###########################

module "kms" {
  count  = var.create_kms_key ? 1 : 0
  source = "../../kms"

  name_prefix = "ecs-${var.name}"
  description = "CMK for ECS cluster ${var.name} exec-command logging and managed storage encryption."
  policy      = data.aws_iam_policy_document.kms[0].json
  tags        = merge(tomap({ Name = "ecs-${var.name}" }), var.tags)
}

###########################
# CloudWatch Log Group (composition)
###########################

module "log_group" {
  count  = local.create_log_group ? 1 : 0
  source = "../../cloudwatch/log_group"

  name              = "/aws/ecs/${var.name}/exec"
  retention_in_days = var.log_group_retention_in_days
  kms_key_id        = var.cloud_watch_encryption_enabled ? local.kms_key_arn : null
  tags              = merge(tomap({ Name = "/aws/ecs/${var.name}/exec" }), var.tags)
}

###########################
# ECS Cluster
###########################

resource "aws_ecs_cluster" "this" {
  name = var.name

  dynamic "setting" {
    for_each = local.cluster_settings
    content {
      name  = setting.value.name
      value = setting.value.value
    }
  }

  dynamic "configuration" {
    for_each = (var.enable_execute_command_logging || local.managed_storage_kms_key_arn != null) ? [1] : []
    content {
      dynamic "execute_command_configuration" {
        for_each = var.enable_execute_command_logging ? [1] : []
        content {
          kms_key_id = local.kms_key_arn
          logging    = var.execute_command_logging

          dynamic "log_configuration" {
            for_each = var.execute_command_logging == "OVERRIDE" ? [1] : []
            content {
              cloud_watch_encryption_enabled = var.cloud_watch_encryption_enabled
              cloud_watch_log_group_name     = local.cloud_watch_log_group_name
              s3_bucket_name                 = var.s3_bucket_name
              s3_bucket_encryption_enabled   = var.s3_bucket_encryption_enabled
              s3_key_prefix                  = var.s3_key_prefix
            }
          }
        }
      }

      dynamic "managed_storage_configuration" {
        for_each = local.managed_storage_kms_key_arn != null ? [1] : []
        content {
          fargate_ephemeral_storage_kms_key_id = local.managed_storage_kms_key_arn
          kms_key_id                           = local.managed_storage_kms_key_arn
        }
      }
    }
  }

  dynamic "service_connect_defaults" {
    for_each = var.service_connect_namespace_arn != null ? [1] : []
    content {
      namespace = var.service_connect_namespace_arn
    }
  }

  tags = merge(tomap({ Name = var.name }), var.tags)
}

###########################
# ECS Cluster Capacity Providers
###########################

resource "aws_ecs_cluster_capacity_providers" "this" {
  cluster_name       = aws_ecs_cluster.this.name
  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = var.default_capacity_provider_strategy
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      base              = default_capacity_provider_strategy.value.base
      weight            = default_capacity_provider_strategy.value.weight
    }
  }
}
