terraform {
  # Optional object attributes require 1.3; also covers moved blocks/preconditions.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # 6.8.0 increased the SQS maximum message size to 1 MiB.
      version = ">= 6.8.0"
    }
  }
}

###########################
# Encryption policy
###########################

data "aws_caller_identity" "current" {
  count = var.create_kms_key && var.key_policy == null ? 1 : 0
}

data "aws_partition" "current" {
  count = var.create_kms_key && var.key_policy == null ? 1 : 0
}

data "aws_region" "current" {
  count = var.create_kms_key && var.key_policy == null && var.region == null ? 1 : 0
}

locals {
  generate_key_policy = var.create_kms_key && var.key_policy == null
  policy_region       = var.region != null ? var.region : try(data.aws_region.current[0].region, null)
  # Names are known without depending on the queue (which depends on this key).
  queue_name_pattern = var.name != null ? var.name : "${var.name_prefix != null ? var.name_prefix : ""}*"
  queue_arn_pattern  = local.generate_key_policy ? "arn:${data.aws_partition.current[0].partition}:sqs:${local.policy_region}:${data.aws_caller_identity.current[0].account_id}:${local.queue_name_pattern}" : null
  generated_key_policy = local.generate_key_policy ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableAccountAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:${data.aws_partition.current[0].partition}:iam::${data.aws_caller_identity.current[0].account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowQueueServiceUse"
        Effect    = "Allow"
        Principal = { AWS = "arn:${data.aws_partition.current[0].partition}:iam::${data.aws_caller_identity.current[0].account_id}:root" }
        Action    = ["kms:Decrypt", "kms:GenerateDataKey"]
        Resource  = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = data.aws_caller_identity.current[0].account_id
            # KMS ViaService names use amazonaws.com in ALL partitions.
            # https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-via-service
            "kms:ViaService" = "sqs.${local.policy_region}.amazonaws.com"
          }
          ArnLike = {
            "kms:EncryptionContext:aws:sqs:arn" = local.queue_arn_pattern
          }
        }
      }
    ]
  }) : null
  effective_kms_master_key_id = var.create_kms_key ? module.kms[0].arn : var.kms_master_key_id
  uses_kms                    = var.create_kms_key || var.kms_master_key_id != null
  tags                        = merge({ Name = coalesce(var.name, var.name_prefix, "sqs") }, var.tags)
}

###########################
# KMS child and permanent moves
###########################

module "kms" {
  source = "../kms"
  count  = var.create_kms_key ? 1 : 0

  customer_master_key_spec = var.key_customer_master_key_spec
  description              = var.key_description
  deletion_window_in_days  = var.key_deletion_window_in_days
  enable_key_rotation      = var.key_enable_key_rotation
  key_usage                = var.key_usage
  is_enabled               = var.key_is_enabled
  name_prefix              = var.key_name_prefix
  policy                   = var.key_policy != null ? var.key_policy : local.generated_key_policy
  region                   = var.region
  tags                     = local.tags
}

moved {
  from = aws_kms_key.sqs
  to   = module.kms[0].aws_kms_key.this
}

moved {
  from = aws_kms_alias.sqs
  to   = module.kms[0].aws_kms_alias.this
}

###########################
# SQS Queue
###########################

resource "aws_sqs_queue" "queue" {
  name                              = var.name
  name_prefix                       = var.name == null ? var.name_prefix : null
  region                            = var.region
  delay_seconds                     = var.delay_seconds
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.content_based_deduplication
  deduplication_scope               = var.deduplication_scope
  fifo_throughput_limit             = var.fifo_throughput_limit
  kms_master_key_id                 = local.effective_kms_master_key_id
  kms_data_key_reuse_period_seconds = local.uses_kms ? var.kms_data_key_reuse_period_seconds : null
  sqs_managed_sse_enabled           = local.uses_kms ? null : var.sqs_managed_sse_enabled
  message_retention_seconds         = var.message_retention_seconds
  max_message_size                  = var.max_message_size
  receive_wait_time_seconds         = var.receive_wait_time_seconds
  visibility_timeout_seconds        = var.visibility_timeout_seconds
  redrive_policy                    = var.redrive_policy
  redrive_allow_policy              = var.redrive_allow_policy
  policy                            = var.policy
  tags                              = local.tags

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]
    content {
      create = timeouts.value.create
      update = timeouts.value.update
      delete = timeouts.value.delete
    }
  }

  lifecycle {
    precondition {
      condition     = !(var.name != null && var.name_prefix != null)
      error_message = "Set name or name_prefix, not both; use name = null for generated naming."
    }
    precondition {
      condition     = var.name == null ? true : (var.fifo_queue ? endswith(var.name, ".fifo") : !endswith(var.name, ".fifo"))
      error_message = "FIFO queue names must end in .fifo; standard queue names must not."
    }
    precondition {
      condition     = var.fifo_queue || (var.content_based_deduplication != true && var.deduplication_scope == null && var.fifo_throughput_limit == null)
      error_message = "Content deduplication, deduplication_scope and fifo_throughput_limit require fifo_queue = true."
    }
    precondition {
      condition     = var.fifo_throughput_limit != "perMessageGroupId" || var.deduplication_scope == "messageGroup"
      error_message = "perMessageGroupId throughput requires deduplication_scope = messageGroup."
    }
    precondition {
      condition     = !var.create_kms_key || var.kms_master_key_id == null
      error_message = "Set create_kms_key = false when supplying kms_master_key_id."
    }
    precondition {
      condition     = !local.uses_kms || var.sqs_managed_sse_enabled == null
      error_message = "Omit sqs_managed_sse_enabled (including false) when using a created or external KMS key."
    }
    precondition {
      condition     = !var.create_kms_key || var.key_customer_master_key_spec == "SYMMETRIC_DEFAULT"
      error_message = "SQS requires a SYMMETRIC_DEFAULT customer-managed key."
    }
    precondition {
      condition     = !var.create_kms_key || var.key_usage == "ENCRYPT_DECRYPT"
      error_message = "SQS requires key_usage = ENCRYPT_DECRYPT."
    }
  }
}
