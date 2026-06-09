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
# Locals
##############################
locals {
  bucket_name      = var.create_s3_bucket ? module.config_bucket[0].s3_bucket_id : var.s3_bucket_name
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

# The Config-specific access policy (GetBucketAcl, ListBucket, PutObject for
# config.amazonaws.com, plus DenyInsecureTransport) is managed here rather than
# passed into the child s3/bucket module because the policy document must
# reference the bucket ARN — which is only known after the module creates the
# bucket — and passing it as a module input would create a Terraform cycle.
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
    resources = [module.config_bucket[0].s3_bucket_arn]
  }

  statement {
    sid    = "AWSConfigBucketExistenceCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:ListBucket"]
    resources = [module.config_bucket[0].s3_bucket_arn]
  }

  statement {
    sid    = "AWSConfigBucketDelivery"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["config.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${module.config_bucket[0].s3_bucket_arn}/${local.s3_delivery_path}"]

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
      module.config_bucket[0].s3_bucket_arn,
      "${module.config_bucket[0].s3_bucket_arn}/*",
    ]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

module "config_bucket" {
  count  = var.create_s3_bucket ? 1 : 0
  source = "../../s3/bucket"

  providers = {
    aws = aws.organization_config_account
  }

  bucket_prefix              = var.s3_bucket_prefix
  bucket_force_destroy       = var.s3_bucket_force_destroy
  bucket_object_lock_enabled = var.s3_bucket_object_lock_enabled

  # SSL enforcement is handled by the inline aws_s3_bucket_policy below,
  # which also includes Config-specific permissions. Disable it in the child
  # module to avoid a separate, conflicting bucket policy resource.
  enforce_ssl = false

  versioning_status = "Enabled"
  sse_algorithm     = "aws:kms"
  enable_kms_key    = false # AWS-managed key by default; use var.s3_kms_key_arn on the delivery channel for CMK

  enable_s3_bucket_logging = var.enable_s3_bucket_logging
  logging_target_bucket    = var.s3_logging_target_bucket
  logging_target_prefix    = var.s3_logging_target_prefix

  tags = merge(tomap({ Name = var.name }), var.tags)
}

resource "aws_s3_bucket_policy" "this" {
  count    = var.create_s3_bucket ? 1 : 0
  provider = aws.organization_config_account

  bucket = module.config_bucket[0].s3_bucket_id
  policy = data.aws_iam_policy_document.config_bucket[0].json

  depends_on = [module.config_bucket]
}

##############################
# Config Recorder
##############################
resource "aws_config_configuration_recorder" "this" {
  provider = aws.organization_config_account

  name     = var.recorder_name
  role_arn = var.recorder_role_arn

  recording_group {
    all_supported                 = var.all_supported
    include_global_resource_types = var.include_global_resource_types
    resource_types                = length(var.resource_types) > 0 ? var.resource_types : null

    dynamic "exclusion_by_resource_types" {
      for_each = length(var.exclusion_resource_types) > 0 ? [1] : []
      content {
        resource_types = var.exclusion_resource_types
      }
    }

    dynamic "recording_strategy" {
      for_each = var.recording_strategy != null ? [var.recording_strategy] : []
      content {
        use_only = recording_strategy.value
      }
    }
  }

  dynamic "recording_mode" {
    for_each = var.recording_frequency != null ? [var.recording_frequency] : []
    content {
      recording_frequency = recording_mode.value
    }
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
  s3_kms_key_arn = var.s3_kms_key_arn
  sns_topic_arn  = var.sns_topic_arn

  snapshot_delivery_properties {
    delivery_frequency = var.delivery_frequency
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

  name                   = each.value.name
  template_s3_uri        = try(each.value.template_s3_uri, null)
  template_body          = try(each.value.template_body, null)
  delivery_s3_bucket     = var.conformance_pack_delivery_s3_bucket
  delivery_s3_key_prefix = var.conformance_pack_delivery_s3_key_prefix
  excluded_accounts      = try(each.value.excluded_accounts, null)

  dynamic "input_parameter" {
    for_each = try(each.value.input_parameters, [])
    content {
      parameter_name  = input_parameter.value.parameter_name
      parameter_value = input_parameter.value.parameter_value
    }
  }

  depends_on = [aws_config_configuration_recorder_status.this]
}
