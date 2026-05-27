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

data "aws_iam_policy_document" "log_delivery" {
  statement {
    sid     = "AllowS3LogDelivery"
    effect  = "Allow"
    actions = ["s3:PutObject"]

    # Bucket ARN is deterministic for S3 — constructed from the fixed bucket name
    resources = ["arn:aws:s3:::${var.bucket}/*"]

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }
  }
}

module "this" {
  source = "../bucket"

  bucket               = var.bucket
  bucket_force_destroy = var.bucket_force_destroy

  # BucketOwnerPreferred + log-delivery-write ACL required by the S3 log delivery service
  object_ownership = "BucketOwnerPreferred"
  acl              = "log-delivery-write"

  # SSE-S3 (AES256) required — S3 log delivery does not support SSE-KMS on target buckets
  sse_algorithm      = "AES256"
  enable_kms_key     = false
  bucket_key_enabled = false

  # Enforce SSL; merge with the log-delivery allow statement above
  enforce_ssl   = true
  bucket_policy = data.aws_iam_policy_document.log_delivery.json

  # Block all public access
  enable_public_access_block = true

  lifecycle_rules   = var.lifecycle_rules
  versioning_status = var.enable_versioning ? "Enabled" : "Disabled"

  tags = var.tags
}
