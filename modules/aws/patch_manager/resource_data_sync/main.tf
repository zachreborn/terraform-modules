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

###########################
# Locals
###########################

locals {
  bucket_name   = var.create_bucket ? "${var.name}-ssm-sync-${data.aws_caller_identity.current.account_id}" : var.bucket_name
  bucket_region = var.create_bucket ? data.aws_region.current.name : var.bucket_region
}

###########################
# S3 Bucket - Central SSM Data
###########################

resource "aws_s3_bucket" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = local.bucket_name
  tags   = merge(tomap({ Name = local.bucket_name }), var.tags)
}

resource "aws_s3_bucket_versioning" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = var.kms_key_arn != null ? "aws:kms" : "AES256"
      kms_master_key_id = var.kms_key_arn
    }
    bucket_key_enabled = var.kms_key_arn != null ? true : null
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id

  rule {
    id     = "expire-ssm-sync-data"
    status = "Enabled"

    expiration {
      days = var.retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = var.retention_days
    }
  }
}

###########################
# S3 Bucket Policy - Cross-Account SSM Access
###########################

data "aws_iam_policy_document" "bucket_policy" {
  count = var.create_bucket ? 1 : 0

  statement {
    sid    = "AllowSSMGetBucketAcl"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.this[0].arn]

    dynamic "condition" {
      for_each = var.org_id != null ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceOrgID"
        values   = [var.org_id]
      }
    }
  }

  statement {
    sid    = "AllowSSMPutObject"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.this[0].arn}/${var.prefix}/*/accountid=*/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }

    dynamic "condition" {
      for_each = var.org_id != null ? [1] : []
      content {
        test     = "StringEquals"
        variable = "aws:SourceOrgID"
        values   = [var.org_id]
      }
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  count  = var.create_bucket ? 1 : 0
  bucket = aws_s3_bucket.this[0].id
  policy = data.aws_iam_policy_document.bucket_policy[0].json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

###########################
# SSM Resource Data Sync
###########################

resource "aws_ssm_resource_data_sync" "this" {
  name = var.name

  s3_destination {
    bucket_name = local.bucket_name
    region      = local.bucket_region
    prefix      = var.prefix
    kms_key_arn = var.kms_key_arn
    sync_format = var.sync_format
  }

  depends_on = [aws_s3_bucket_policy.this]
}
