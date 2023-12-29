########################################################
# This module is deprecated, please use `bucket` module instead which includes all the features of this module.
########################################################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

# Public website S3 bucket requires public access
#tfsec:ignore:aws-s3-specify-public-access-block
resource "aws_s3_bucket" "this" {
  bucket = var.bucket
  tags   = var.tags

}

resource "aws_s3_bucket_policy" "public_website_access" {
  bucket = aws_s3_bucket.this.id
  policy = var.policy
}

resource "aws_s3_bucket_website_configuration" "this" {
  bucket = aws_s3_bucket.this.bucket

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}
