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
data "aws_region" "current" {}

###########################
# Locals
###########################

locals {
  # Resolve the KMS key ARN used to encrypt the gateway log group: either the
  # key created by this module or a caller-supplied key.
  kms_key_arn = var.create_cloudwatch_log_group && var.create_kms_key ? module.kms_key[0].arn : var.kms_key_id

  # Resolve the CloudWatch log group ARN wired to the gateway: a caller-supplied
  # ARN takes precedence over one created by this module.
  cloudwatch_log_group_arn = var.cloudwatch_log_group_arn != null ? var.cloudwatch_log_group_arn : (var.create_cloudwatch_log_group ? module.cloudwatch_log_group[0].arn : null)

  # Whether this module creates the IAM role file shares use to reach S3. A
  # caller-supplied role_arn always wins, so we never create one in that case.
  create_iam_role = var.create_iam_role && var.role_arn == null

  # Resolve the role ARN file shares assume to access their S3 buckets: a
  # caller-supplied ARN takes precedence over one created by this module.
  role_arn = var.role_arn != null ? var.role_arn : (local.create_iam_role ? module.iam_role[0].arn : null)

  # Resolve the gateway ARN that cache disks and file shares attach to: a
  # caller-supplied ARN (existing, externally activated gateway) takes
  # precedence over the gateway created by this module.
  gateway_arn = var.gateway_arn != null ? var.gateway_arn : one(aws_storagegateway_gateway.this[*].arn)
}

###########################
# KMS Encryption Key
###########################

module "kms_key" {
  count  = var.create_cloudwatch_log_group && var.create_kms_key ? 1 : 0
  source = "../kms"

  deletion_window_in_days = var.kms_key_deletion_window_in_days
  description             = var.kms_key_description
  enable_key_rotation     = var.kms_key_enable_key_rotation
  name_prefix             = var.kms_key_name_prefix
  tags                    = var.tags
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "Enable IAM User Permissions",
        "Effect" = "Allow",
        "Principal" = {
          "AWS" = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action"   = "kms:*",
        "Resource" = "*"
      },
      {
        "Sid"    = "Allow CloudWatch Logs to use the key",
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "logs.${data.aws_region.current.region}.amazonaws.com"
        },
        "Action" = [
          "kms:Decrypt*",
          "kms:Describe*",
          "kms:Encrypt*",
          "kms:GenerateDataKey*",
          "kms:ReEncrypt*"
        ],
        "Resource" = "*",
        "Condition" = {
          "ArnEquals" = {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
          }
        }
      }
    ]
  })
}

###########################
# CloudWatch Log Group
###########################

module "cloudwatch_log_group" {
  count  = var.create_cloudwatch_log_group && var.cloudwatch_log_group_arn == null ? 1 : 0
  source = "../cloudwatch/log_group"

  kms_key_id        = local.kms_key_arn
  name_prefix       = var.cloudwatch_name_prefix
  retention_in_days = var.cloudwatch_retention_in_days
  tags              = var.tags
}

###########################
# IAM Role for S3 Access
###########################
#
# S3 file shares assume an IAM role to read and write objects in their backing
# bucket. This module can create that role (create_iam_role = true) scoped to the
# buckets in s3_bucket_arns, or callers can bring their own by setting role_arn.

data "aws_iam_policy_document" "assume_role" {
  count = local.create_iam_role ? 1 : 0

  statement {
    sid     = "AllowStorageGatewayAssumeRole"
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["storagegateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  count = local.create_iam_role ? 1 : 0

  statement {
    sid    = "AllowBucketLevelActions"
    effect = "Allow"
    actions = [
      "s3:GetAccelerateConfiguration",
      "s3:GetBucketLocation",
      "s3:GetBucketVersioning",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
    ]
    resources = var.s3_bucket_arns
  }

  statement {
    sid    = "AllowObjectLevelActions"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:DeleteObjectVersion",
      "s3:GetObject",
      "s3:GetObjectAcl",
      "s3:GetObjectVersion",
      "s3:ListMultipartUploadParts",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]
    resources = [for arn in var.s3_bucket_arns : "${arn}/*"]
  }

  lifecycle {
    precondition {
      condition     = length(var.s3_bucket_arns) > 0
      error_message = "s3_bucket_arns must contain at least one bucket ARN when create_iam_role is true; an IAM policy cannot be created with no resources."
    }
  }
}

module "iam_policy" {
  count  = local.create_iam_role ? 1 : 0
  source = "../iam/policy"

  name_prefix = var.iam_name_prefix
  description = "Allows the S3 File Gateway to read and write objects in the buckets backing its file shares."
  policy      = data.aws_iam_policy_document.s3_access[0].json
  tags        = var.tags
}

module "iam_role" {
  count  = local.create_iam_role ? 1 : 0
  source = "../iam/role"

  name_prefix        = var.iam_name_prefix
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  policy_arns        = [module.iam_policy[0].arn]
  description        = "Assumed by AWS Storage Gateway to access the S3 buckets backing its file shares."
  tags               = var.tags
}

###########################
# Storage Gateway
###########################

resource "aws_storagegateway_gateway" "this" {
  # Not created when gateway_arn supplies an existing, externally activated
  # gateway. On-premises appliances only honor an activation for a short window
  # after the activation key is generated, which pipeline-driven applies cannot
  # reliably meet - activate out of band and pass the resulting ARN instead.
  count = var.gateway_arn == null ? 1 : 0

  activation_key                              = var.activation_key
  average_download_rate_limit_in_bits_per_sec = var.average_download_rate_limit_in_bits_per_sec
  average_upload_rate_limit_in_bits_per_sec   = var.average_upload_rate_limit_in_bits_per_sec
  cloudwatch_log_group_arn                    = local.cloudwatch_log_group_arn
  gateway_ip_address                          = var.gateway_ip_address
  gateway_name                                = var.gateway_name
  gateway_timezone                            = var.gateway_timezone
  gateway_type                                = var.gateway_type
  gateway_vpc_endpoint                        = var.gateway_vpc_endpoint
  smb_file_share_visibility                   = var.smb_file_share_visibility
  smb_guest_password                          = var.smb_guest_password
  smb_security_strategy                       = var.smb_security_strategy
  tags                                        = merge(tomap({ Name = var.gateway_name }), var.tags)

  dynamic "maintenance_start_time" {
    for_each = var.maintenance_start_time != null ? [var.maintenance_start_time] : []
    content {
      day_of_month   = maintenance_start_time.value.day_of_month
      day_of_week    = maintenance_start_time.value.day_of_week
      hour_of_day    = maintenance_start_time.value.hour_of_day
      minute_of_hour = maintenance_start_time.value.minute_of_hour
    }
  }

  dynamic "smb_active_directory_settings" {
    for_each = var.smb_active_directory_settings != null ? [var.smb_active_directory_settings] : []
    content {
      domain_controllers  = smb_active_directory_settings.value.domain_controllers
      domain_name         = smb_active_directory_settings.value.domain_name
      organizational_unit = smb_active_directory_settings.value.organizational_unit
      password            = smb_active_directory_settings.value.password
      timeout_in_seconds  = smb_active_directory_settings.value.timeout_in_seconds
      username            = smb_active_directory_settings.value.username
    }
  }

  lifecycle {
    precondition {
      condition     = var.activation_key != null || var.gateway_ip_address != null
      error_message = "One of activation_key or gateway_ip_address is required when the module creates the gateway (gateway_arn is null)."
    }
  }
}

###########################
# Cache Disks
###########################

resource "aws_storagegateway_cache" "this" {
  for_each = var.cache_disk_ids

  disk_id     = each.value
  gateway_arn = local.gateway_arn
}

###########################
# File System Associations
###########################

resource "aws_storagegateway_file_system_association" "this" {
  for_each = var.file_system_associations

  audit_destination_arn = each.value.audit_destination_arn
  gateway_arn           = local.gateway_arn
  location_arn          = each.value.location_arn
  password              = each.value.password
  tags                  = merge(tomap({ Name = each.key }), var.tags)
  username              = each.value.username

  dynamic "cache_attributes" {
    for_each = each.value.cache_attributes != null ? [each.value.cache_attributes] : []
    content {
      cache_stale_timeout_in_seconds = cache_attributes.value.cache_stale_timeout_in_seconds
    }
  }
}

###########################
# S3 SMB File Shares
###########################
#
# SMB file shares expose an S3 bucket (location_arn) over SMB. Requires a FILE_S3
# gateway. ActiveDirectory authentication requires the gateway to be domain
# joined via smb_active_directory_settings.

resource "aws_storagegateway_smb_file_share" "this" {
  for_each = var.s3_smb_file_shares

  access_based_enumeration = each.value.access_based_enumeration
  admin_user_list          = each.value.admin_user_list
  audit_destination_arn    = each.value.audit_destination_arn
  authentication           = each.value.authentication
  bucket_region            = each.value.bucket_region
  case_sensitivity         = each.value.case_sensitivity
  default_storage_class    = each.value.default_storage_class
  file_share_name          = each.value.file_share_name
  gateway_arn              = local.gateway_arn
  guess_mime_type_enabled  = each.value.guess_mime_type_enabled
  invalid_user_list        = each.value.invalid_user_list
  kms_encrypted            = each.value.kms_encrypted
  kms_key_arn              = each.value.kms_key_arn
  location_arn             = each.value.location_arn
  notification_policy      = each.value.notification_policy
  object_acl               = each.value.object_acl
  oplocks_enabled          = each.value.oplocks_enabled
  read_only                = each.value.read_only
  requester_pays           = each.value.requester_pays
  role_arn                 = each.value.role_arn != null ? each.value.role_arn : local.role_arn
  smb_acl_enabled          = each.value.smb_acl_enabled
  tags                     = merge(tomap({ Name = each.key }), var.tags)
  valid_user_list          = each.value.valid_user_list
  vpc_endpoint_dns_name    = each.value.vpc_endpoint_dns_name

  dynamic "cache_attributes" {
    for_each = each.value.cache_attributes != null ? [each.value.cache_attributes] : []
    content {
      cache_stale_timeout_in_seconds = cache_attributes.value.cache_stale_timeout_in_seconds
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.role_arn != null || local.role_arn != null
      error_message = "S3 SMB file share \"${each.key}\" has no IAM role to assume: set its role_arn, the module-level role_arn, or create_iam_role = true."
    }
  }
}

###########################
# S3 NFS File Shares
###########################
#
# NFS file shares expose an S3 bucket (location_arn) over NFS to the hosts in
# client_list. Requires a FILE_S3 gateway.

resource "aws_storagegateway_nfs_file_share" "this" {
  for_each = var.s3_nfs_file_shares

  audit_destination_arn   = each.value.audit_destination_arn
  bucket_region           = each.value.bucket_region
  client_list             = each.value.client_list
  default_storage_class   = each.value.default_storage_class
  file_share_name         = each.value.file_share_name
  gateway_arn             = local.gateway_arn
  guess_mime_type_enabled = each.value.guess_mime_type_enabled
  kms_encrypted           = each.value.kms_encrypted
  kms_key_arn             = each.value.kms_key_arn
  location_arn            = each.value.location_arn
  notification_policy     = each.value.notification_policy
  object_acl              = each.value.object_acl
  read_only               = each.value.read_only
  requester_pays          = each.value.requester_pays
  role_arn                = each.value.role_arn != null ? each.value.role_arn : local.role_arn
  squash                  = each.value.squash
  tags                    = merge(tomap({ Name = each.key }), var.tags)
  vpc_endpoint_dns_name   = each.value.vpc_endpoint_dns_name

  dynamic "cache_attributes" {
    for_each = each.value.cache_attributes != null ? [each.value.cache_attributes] : []
    content {
      cache_stale_timeout_in_seconds = cache_attributes.value.cache_stale_timeout_in_seconds
    }
  }

  dynamic "nfs_file_share_defaults" {
    for_each = each.value.nfs_file_share_defaults != null ? [each.value.nfs_file_share_defaults] : []
    content {
      directory_mode = nfs_file_share_defaults.value.directory_mode
      file_mode      = nfs_file_share_defaults.value.file_mode
      group_id       = nfs_file_share_defaults.value.group_id
      owner_id       = nfs_file_share_defaults.value.owner_id
    }
  }

  lifecycle {
    precondition {
      condition     = each.value.role_arn != null || local.role_arn != null
      error_message = "S3 NFS file share \"${each.key}\" has no IAM role to assume: set its role_arn, the module-level role_arn, or create_iam_role = true."
    }
  }
}
