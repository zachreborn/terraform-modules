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

###########################
# Locals
###########################

locals {
  s3_bucket_name = var.s3_bucket_name != null ? var.s3_bucket_name : "${var.name}-patch-logs-${data.aws_caller_identity.current.account_id}"
  sns_topic_arn  = var.create_sns_topic ? aws_sns_topic.this[0].arn : var.sns_topic_arn
}

###########################
# IAM - Maintenance Window Service Role
###########################

data "aws_iam_policy_document" "assume_role" {
  statement {
    sid     = "AllowSSMAssumeRole"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "maintenance_window" {
  name               = "${var.name}-mw-service-role"
  description        = "Service role for SSM Maintenance Window ${var.name}"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = merge(tomap({ Name = "${var.name}-mw-service-role" }), var.tags)
}

resource "aws_iam_role_policy_attachment" "maintenance_window" {
  role       = aws_iam_role.maintenance_window.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AmazonSSMMaintenanceWindowRole"
}

###########################
# IAM - SNS Notification Inline Policy
###########################

data "aws_iam_policy_document" "sns_notification" {
  count = var.enable_sns_notification ? 1 : 0

  statement {
    sid       = "AllowSNSPublish"
    actions   = ["sns:Publish"]
    resources = [local.sns_topic_arn]
  }
}

resource "aws_iam_role_policy" "sns_notification" {
  count  = var.enable_sns_notification ? 1 : 0
  name   = "${var.name}-sns-notification"
  role   = aws_iam_role.maintenance_window.id
  policy = data.aws_iam_policy_document.sns_notification[0].json
}

###########################
# S3 Bucket - Patch Logs
###########################

resource "aws_s3_bucket" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = local.s3_bucket_name
  tags   = merge(tomap({ Name = local.s3_bucket_name }), var.tags)
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.s3_kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.s3_kms_key_arn
    }
    bucket_key_enabled = var.s3_kms_key_arn != null ? true : null
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.create_s3_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "expire-patch-logs"
    status = "Enabled"

    expiration {
      days = var.s3_log_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.s3_log_retention_days
    }
  }
}

###########################
# SNS Topic - Patch Notifications
###########################

resource "aws_sns_topic" "this" {
  count             = var.create_sns_topic ? 1 : 0
  name              = "${var.name}-patch-notifications"
  kms_master_key_id = var.sns_kms_key_id
  tags              = merge(tomap({ Name = "${var.name}-patch-notifications" }), var.tags)
}

data "aws_iam_policy_document" "sns_topic_policy" {
  count = var.create_sns_topic ? 1 : 0

  statement {
    sid    = "AllowSSMPublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = [aws_sns_topic.this[0].arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

resource "aws_sns_topic_policy" "this" {
  count  = var.create_sns_topic ? 1 : 0
  arn    = aws_sns_topic.this[0].arn
  policy = data.aws_iam_policy_document.sns_topic_policy[0].json
}

###########################
# Maintenance Window
###########################

resource "aws_ssm_maintenance_window" "this" {
  name                       = var.name
  description                = var.description
  schedule                   = var.schedule
  schedule_timezone          = var.schedule_timezone
  schedule_offset            = var.schedule_offset
  duration                   = var.duration
  cutoff                     = var.cutoff
  allow_unassociated_targets = var.allow_unassociated_targets
  enabled                    = var.enabled
  start_date                 = var.start_date
  end_date                   = var.end_date

  tags = merge(tomap({ Name = var.name }), var.tags)

  lifecycle {
    precondition {
      condition     = !var.enable_s3_logging || var.create_s3_bucket || var.s3_bucket_name != null
      error_message = "enable_s3_logging requires either create_s3_bucket = true or s3_bucket_name to be provided."
    }
    precondition {
      condition     = !var.enable_sns_notification || var.create_sns_topic || var.sns_topic_arn != null
      error_message = "enable_sns_notification requires either create_sns_topic = true or sns_topic_arn to be provided."
    }
    precondition {
      condition     = var.cutoff < var.duration
      error_message = "cutoff must be less than duration."
    }
  }
}

###########################
# Maintenance Window Targets
###########################

resource "aws_ssm_maintenance_window_target" "this" {
  for_each = var.targets

  window_id         = aws_ssm_maintenance_window.this.id
  name              = each.key
  description       = each.value.description
  resource_type     = each.value.resource_type
  owner_information = each.value.owner_information

  targets {
    key    = "tag:${each.value.tag_key}"
    values = each.value.tag_values
  }
}

###########################
# Maintenance Window Tasks
###########################

resource "aws_ssm_maintenance_window_task" "this" {
  for_each = aws_ssm_maintenance_window_target.this

  window_id        = aws_ssm_maintenance_window.this.id
  name             = "${var.name}-${each.key}"
  description      = "Run AWS-RunPatchBaseline on target ${each.key}"
  task_type        = "RUN_COMMAND"
  task_arn         = "AWS-RunPatchBaseline"
  priority         = var.task_priority
  service_role_arn = aws_iam_role.maintenance_window.arn
  max_concurrency  = var.max_concurrency
  max_errors       = var.max_errors

  targets {
    key    = "WindowTargetIds"
    values = [each.value.id]
  }

  task_invocation_parameters {
    run_command_parameters {
      service_role_arn     = var.enable_sns_notification ? aws_iam_role.maintenance_window.arn : null
      timeout_seconds      = var.timeout_seconds
      document_hash        = var.document_hash
      document_hash_type   = var.document_hash != null ? var.document_hash_type : null
      document_version     = var.document_version
      comment              = var.task_comment
      output_s3_bucket     = var.enable_s3_logging ? local.s3_bucket_name : null
      output_s3_key_prefix = var.enable_s3_logging ? var.s3_key_prefix : null

      parameter {
        name   = "Operation"
        values = [var.patch_operation]
      }

      parameter {
        name   = "RebootOption"
        values = [var.reboot_option]
      }

      dynamic "notification_config" {
        for_each = var.enable_sns_notification ? [1] : []
        content {
          notification_arn    = local.sns_topic_arn
          notification_events = var.notification_events
          notification_type   = var.notification_type
        }
      }
    }
  }
}
