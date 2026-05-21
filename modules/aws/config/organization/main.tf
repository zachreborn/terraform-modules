##############################
# Provider Configuration
##############################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws.organization_management_account, aws.organization_config_account]
    }
  }
}

##############################
# Data Sources
##############################
data "aws_caller_identity" "config_account" {
  provider = aws.organization_config_account
}

##############################
# Locals
##############################
locals {
  bucket_name      = var.create_s3_bucket ? aws_s3_bucket.this[0].id : var.s3_bucket_name
  bucket_arn       = var.create_s3_bucket ? aws_s3_bucket.this[0].arn : "arn:aws:s3:::${var.s3_bucket_name}"
  s3_delivery_path = var.s3_key_prefix != null ? "${var.s3_key_prefix}/AWSLogs/*/Config/*" : "AWSLogs/*/Config/*"
}

##############################
# Organizations Delegated Admin
##############################
resource "aws_organizations_delegated_administrator" "this" {
  provider          = aws.organization_management_account
  account_id        = var.admin_account_id
  service_principal = "config.amazonaws.com"
}

##############################
# Config S3 Bucket
##############################
data "aws_iam_policy_document" "config_bucket" {
  count = var.create_s3_bucket ? 1 : 0

  statement {
    sid    = "AWSConfigBucketPermissionsCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this[0].arn]
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this[0].arn]
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[0].arn}/${local.s3_delivery_path}"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid    = "DenyInsecureTransport"
    effect = "Deny"

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }

    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this[0].arn,
      "${aws_s3_bucket.this[0].arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket" "this" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.organization_config_account

  bucket_prefix = var.s3_bucket_prefix # e.g., "config-" yields globally unique name
  force_destroy = false
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.organization_config_account

  bucket = aws_s3_bucket.this[0].id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.organization_config_account

  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.organization_config_account

  bucket = aws_s3_bucket.this[0].id

  rule {
    bucket_key_enabled = true

    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms" # SSE-KMS with AWS managed key
    }
  }
}

resource "aws_s3_bucket_versioning" "this" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.organization_config_account

  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "this" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.organization_config_account

  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.config_bucket[0].json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

##############################
# Config Recorder
##############################
resource "aws_config_configuration_recorder" "this" {
  provider = aws.organization_config_account

  name     = var.recorder_name
  role_arn = var.recorder_role_arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = var.include_global_resource_types
  }
}

##############################
# Config Delivery Channel
##############################
resource "aws_config_delivery_channel" "this" {
  provider = aws.organization_config_account

  name           = var.delivery_channel_name
  s3_bucket_name = local.bucket_name
  s3_key_prefix  = var.s3_key_prefix
  sns_topic_arn  = var.sns_topic_arn

  snapshot_delivery_properties {
    delivery_frequency = var.delivery_frequency # How often Config snapshots are delivered
  }

  depends_on = [aws_config_configuration_recorder.this]
}

##############################
# Config Recorder Status
##############################
resource "aws_config_configuration_recorder_status" "this" {
  provider = aws.organization_config_account

  name       = aws_config_configuration_recorder.this.name
  is_enabled = true

  depends_on = [aws_config_delivery_channel.this]
}

##############################
# Organization Conformance Packs
##############################
resource "aws_config_organization_conformance_pack" "this" {
  for_each = var.enable_conformance_packs ? { for pack in var.conformance_packs : pack.name => pack } : {}
  provider = aws.organization_config_account

  name            = each.value.name
  template_s3_uri = try(each.value.template_s3_uri, null)
  template_body   = try(each.value.template_body, null)

  depends_on = [aws_config_configuration_recorder_status.this]
}
