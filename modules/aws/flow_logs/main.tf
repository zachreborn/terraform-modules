terraform {
  # >= 1.2.0: lifecycle.precondition (used below to enforce the "exactly one
  # target" contract on aws_kms_key.key) was introduced in Terraform 1.2 /
  # OpenTofu (all versions, since OpenTofu forked after Terraform 1.6).
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.25.0"
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

  # try() guards against the case where none of the five target variables are
  # set (all null): coalesce() would otherwise fail with "no non-null,
  # non-empty-string arguments" when static analysis tools (e.g. tflint)
  # evaluate the module with all variables left at their defaults. Real
  # callers must still provide exactly one target list -- that contract is
  # enforced explicitly by the lifecycle precondition on aws_kms_key.key
  # below, rather than relying on coalesce() itself to error out.
  flow_logs_source = try(coalesce(
    var.flow_eni_ids,
    var.flow_subnet_ids,
    var.flow_transit_gateway_ids,
    var.flow_transit_gateway_attachment_ids,
    var.flow_vpc_ids
  ), [])
}

###########################
# KMS Encryption Key
###########################

resource "aws_kms_key" "key" {
  customer_master_key_spec = var.key_customer_master_key_spec
  description              = var.key_description
  deletion_window_in_days  = var.key_deletion_window_in_days
  enable_key_rotation      = var.key_enable_key_rotation
  key_usage                = var.key_usage
  is_enabled               = var.key_is_enabled
  tags                     = var.tags

  lifecycle {
    precondition {
      # Count -- rather than just checking non-null -- so that supplying two or
      # more target variables is rejected too. Without this, aws_flow_log.this
      # would set multiple mutually exclusive target arguments (e.g. both
      # subnet_id and vpc_id) from local.flow_logs_source, which the provider
      # would only reject once it reaches AWS, not with a clear module error.
      condition = (
        (var.flow_eni_ids != null ? 1 : 0) +
        (var.flow_subnet_ids != null ? 1 : 0) +
        (var.flow_transit_gateway_ids != null ? 1 : 0) +
        (var.flow_transit_gateway_attachment_ids != null ? 1 : 0) +
        (var.flow_vpc_ids != null ? 1 : 0)
      ) == 1
      error_message = "Exactly one of flow_eni_ids, flow_subnet_ids, flow_transit_gateway_ids, flow_transit_gateway_attachment_ids, or flow_vpc_ids must be provided."
    }
    precondition {
      # Catches the edge case where the one supplied target variable is a
      # non-null but empty list (e.g. flow_vpc_ids = []): the count above
      # would pass, but flow_logs_source would resolve to [] and silently
      # create zero flow logs instead of failing explicitly.
      condition     = length(local.flow_logs_source) > 0
      error_message = "The one target list provided (one of flow_eni_ids, flow_subnet_ids, flow_transit_gateway_ids, flow_transit_gateway_attachment_ids, flow_vpc_ids) must not be empty."
    }
  }

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
        "Effect" = "Allow",
        "Principal" = {
          "Service" = "logs.${data.aws_region.current.region}.amazonaws.com"
        },
        "Action" = [
          "kms:Encrypt*",
          "kms:Decrypt*",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:Describe*"
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

resource "aws_kms_alias" "alias" {
  name_prefix   = var.key_name_prefix
  target_key_id = aws_kms_key.key.key_id
}

###########################
# CloudWatch Log Group
###########################

resource "aws_cloudwatch_log_group" "log_group" {
  deletion_protection_enabled = var.cloudwatch_deletion_protection_enabled
  kms_key_id                  = aws_kms_key.key.arn
  name_prefix                 = var.cloudwatch_name_prefix
  retention_in_days           = var.cloudwatch_retention_in_days
  tags                        = var.tags
}

###########################
# IAM Policy
###########################
resource "aws_iam_policy" "policy" {
  description = var.iam_policy_description
  name_prefix = var.iam_policy_name_prefix
  path        = var.iam_policy_path
  tags        = var.tags
  #tfsec:ignore:aws-iam-no-policy-wildcards
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      Resource = [
        "${aws_cloudwatch_log_group.log_group.arn}:*"
      ]
    }]
  })
}

###########################
# IAM Role
###########################

resource "aws_iam_role" "role" {
  assume_role_policy    = var.iam_role_assume_role_policy
  description           = var.iam_role_description
  force_detach_policies = var.iam_role_force_detach_policies
  max_session_duration  = var.iam_role_max_session_duration
  name_prefix           = var.iam_role_name_prefix
  permissions_boundary  = var.iam_role_permissions_boundary
}

resource "aws_iam_role_policy_attachment" "role_attach" {
  role       = aws_iam_role.role.name
  policy_arn = aws_iam_policy.policy.arn
}

###########################
# Flow Log
###########################
resource "aws_flow_log" "this" {
  count                         = length(local.flow_logs_source)
  deliver_cross_account_role    = var.flow_deliver_cross_account_role
  eni_id                        = var.flow_eni_ids != null ? local.flow_logs_source[count.index] : null
  iam_role_arn                  = aws_iam_role.role.arn
  log_destination_type          = var.flow_log_destination_type
  log_destination               = aws_cloudwatch_log_group.log_group.arn
  log_format                    = var.flow_log_format
  max_aggregation_interval      = var.flow_max_aggregation_interval
  subnet_id                     = var.flow_subnet_ids != null ? local.flow_logs_source[count.index] : null
  tags                          = var.tags
  transit_gateway_id            = var.flow_transit_gateway_ids != null ? local.flow_logs_source[count.index] : null
  transit_gateway_attachment_id = var.flow_transit_gateway_attachment_ids != null ? local.flow_logs_source[count.index] : null
  traffic_type                  = var.flow_traffic_type
  vpc_id                        = var.flow_vpc_ids != null ? local.flow_logs_source[count.index] : null
}
