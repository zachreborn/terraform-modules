###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0: default_capacity_provider_strategy's object type uses optional()
  # attributes (stable since Terraform 1.3 / OpenTofu 1.6).
  required_version = ">= 1.3.0"
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

  # This document is the *key policy* for the CMK created via the kms module
  # below. A KMS key policy's scope is implicitly the key it is attached to, so
  # `resources = ["*"]` is the required (and only valid) form: the key ARN does
  # not exist when the policy is authored and cannot be self-referenced. The
  # wildcard therefore does not grant access to any other resource, so the
  # following IAM "unconstrained resource" findings are false positives here.
  # checkov:skip=CKV_AWS_111:KMS key policy scope is the key itself; "*" is the required resource form
  # checkov:skip=CKV_AWS_356:KMS key policy scope is the key itself; "*" is the required resource form
  # checkov:skip=CKV_AWS_109:KMS key policy scope is the key itself; "*" is the required resource form

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

  # This CMK is also assigned to managed_storage_configuration's
  # fargate_ephemeral_storage_kms_key_id by default (see local.managed_storage_kms_key_arn).
  # AWS requires these exact grants for the fargate.amazonaws.com service
  # principal, scoped to this cluster via the encryption context, or Fargate
  # tasks fail to launch with encrypted ephemeral storage. See:
  # https://docs.aws.amazon.com/AmazonECS/latest/developerguide/fargate-create-storage-key.html
  dynamic "statement" {
    for_each = var.managed_storage_kms_key_arn == null ? [1] : []
    content {
      sid    = "AllowFargateGenerateDataKey"
      effect = "Allow"
      actions = [
        "kms:GenerateDataKeyWithoutPlaintext",
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["fargate.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:EncryptionContext:aws:ecs:clusterName"
        values   = [var.name]
      }
    }
  }

  dynamic "statement" {
    for_each = var.managed_storage_kms_key_arn == null ? [1] : []
    content {
      sid    = "AllowFargateCreateGrant"
      effect = "Allow"
      actions = [
        "kms:CreateGrant",
      ]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["fargate.amazonaws.com"]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:EncryptionContext:aws:ecs:clusterAccount"
        values   = [data.aws_caller_identity.current.account_id]
      }
      condition {
        test     = "StringEquals"
        variable = "kms:EncryptionContext:aws:ecs:clusterName"
        values   = [var.name]
      }
      condition {
        test     = "ForAllValues:StringEquals"
        variable = "kms:GrantOperations"
        values   = ["Decrypt"]
      }
    }
  }

  dynamic "statement" {
    for_each = var.managed_storage_kms_key_arn == null ? [1] : []
    content {
      sid       = "AllowFargateDescribeKey"
      effect    = "Allow"
      actions   = ["kms:DescribeKey"]
      resources = ["*"]
      principals {
        type        = "Service"
        identifiers = ["fargate.amazonaws.com"]
      }
    }
  }
}

###########################
# Locals
###########################

locals {
  # Effective KMS key ARN for exec-command logging encryption.
  kms_key_arn = var.create_kms_key ? module.kms[0].arn : var.kms_key_arn

  # Effective KMS key ARN for Fargate managed (ephemeral) storage encryption.
  # Defaults to the created CMK when one is created. Deliberately not a
  # `coalesce()` call: coalesce() errors if every argument is null, but null is
  # a legitimate outcome here (create_kms_key = false with no BYO
  # managed_storage_kms_key_arn just means managed storage isn't encrypted
  # with a CMK) -- the managed_storage_configuration dynamic block below
  # already expects and handles that null case.
  managed_storage_kms_key_arn = (
    var.managed_storage_kms_key_arn != null
    ? var.managed_storage_kms_key_arn
    : (var.create_kms_key ? module.kms[0].arn : null)
  )

  create_log_group = var.enable_execute_command_logging && var.create_cloud_watch_log_group

  # Effective exec-command CloudWatch log group name. Must gate on
  # `local.create_log_group` (not `var.create_cloud_watch_log_group` alone),
  # since that's the actual condition the log_group module's `count` uses --
  # disabling enable_execute_command_logging also skips creating the module
  # even when create_cloud_watch_log_group defaults to true.
  cloud_watch_log_group_name = local.create_log_group ? module.log_group[0].name : var.cloud_watch_log_group_name
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

  # CMK-backed kms_key_id and cloud_watch_encryption_enabled are enabled by default.
  # Checkov cannot statically resolve the value through local.kms_key_arn (module.kms[0].arn)
  # and the triple-nested dynamic configuration/execute_command_configuration/log_configuration
  # blocks (bridgecrewio/checkov#2985, #4921, #6265 — graph-resolution limitation).
  # checkov:skip=CKV_AWS_224:CMK-backed kms_key_id and cloud_watch_encryption_enabled are enabled by default; Checkov cannot statically resolve through local.kms_key_arn and the triple-nested dynamic configuration/execute_command_configuration/log_configuration blocks

  # Declared as a static block (rather than folded into the dynamic block below)
  # so static analyzers can verify the secure-by-default containerInsights value.
  setting {
    name  = "containerInsights"
    value = var.container_insights
  }

  # Any caller-supplied settings beyond containerInsights.
  dynamic "setting" {
    for_each = var.additional_settings
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
