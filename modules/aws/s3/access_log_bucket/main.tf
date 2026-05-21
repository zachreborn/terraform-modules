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
# S3 Access Log Bucket
###########################

resource "aws_s3_bucket" "this" {
  bucket        = var.bucket
  force_destroy = var.bucket_force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    # BucketOwnerPreferred is required for log-delivery-write ACL to function correctly
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  # log-delivery-write grants the S3 log delivery group write permissions
  depends_on = [aws_s3_bucket_ownership_controls.this]
  bucket     = aws_s3_bucket.this.id
  acl        = "log-delivery-write"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  rule {
    apply_server_side_encryption_by_default {
      # SSE-S3 (AES256) is required — the S3 log delivery service does not support SSE-KMS on target buckets
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

###########################
# Lifecycle Configuration
###########################

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count  = var.lifecycle_rules == null ? 0 : 1
  bucket = aws_s3_bucket.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules
    content {
      id     = rule.value.id
      status = rule.value.status

      dynamic "abort_incomplete_multipart_upload" {
        for_each = try(flatten([rule.value.abort_incomplete_multipart_upload]), [])
        content {
          days_after_initiation = try(abort_incomplete_multipart_upload.value.days_after_initiation, null)
        }
      }

      dynamic "expiration" {
        for_each = try(flatten([rule.value.expiration]), [])
        content {
          date                         = try(expiration.value.date, null)
          days                         = try(expiration.value.days, null)
          expired_object_delete_marker = try(expiration.value.expired_object_delete_marker, null)
        }
      }

      dynamic "filter" {
        for_each = try(flatten([rule.value.filter]), [])
        content {
          object_size_greater_than = try(filter.value.object_size_greater_than, null)
          object_size_less_than    = try(filter.value.object_size_less_than, null)
          prefix                   = try(filter.value.prefix, null)
          dynamic "tag" {
            for_each = try(rule.value.filter.tag, [])
            content {
              key   = tag.value.key
              value = tag.value.value
            }
          }
        }
      }

      dynamic "noncurrent_version_expiration" {
        for_each = try(flatten([rule.value.noncurrent_version_expiration]), [])
        content {
          newer_noncurrent_versions = try(noncurrent_version_expiration.value.newer_noncurrent_versions, null)
          noncurrent_days           = try(noncurrent_version_expiration.value.noncurrent_days, null)
        }
      }

      dynamic "noncurrent_version_transition" {
        for_each = try(rule.value.noncurrent_version_transition, [])
        content {
          newer_noncurrent_versions = try(noncurrent_version_transition.value.newer_noncurrent_versions, null)
          noncurrent_days           = try(noncurrent_version_transition.value.noncurrent_days, null)
          storage_class             = try(noncurrent_version_transition.value.storage_class, null)
        }
      }

      dynamic "transition" {
        for_each = try(rule.value.transition, [])
        content {
          date          = try(transition.value.date, null)
          days          = try(transition.value.days, null)
          storage_class = try(transition.value.storage_class, null)
        }
      }
    }
  }
}

###########################
# Versioning (Optional)
###########################

resource "aws_s3_bucket_versioning" "this" {
  count  = var.enable_versioning ? 1 : 0
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

###########################
# Bucket Policy
###########################

data "aws_iam_policy_document" "this" {
  statement {
    sid     = "DenyInsecureTransport"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.this.arn,
      "${aws_s3_bucket.this.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }

  statement {
    sid     = "AllowS3LogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    resources = ["${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
  }
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.this.json
}
