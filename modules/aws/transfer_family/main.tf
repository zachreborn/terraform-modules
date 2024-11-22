###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
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

###########################
# Module Configuration
###########################

##############
# Create logging IAM role
##############

##############
# Create CloudWatch log group
##############

##############
# Create the AWS transfer family server
##############

resource "aws_transfer_server" "this" {
  certificate                      = var.certificate
  directory_id                     = var.directory_id
  domain                           = var.storage_location
  endpoint_type                    = var.endpoint_type
  function                         = var.function
  host_key                         = var.host_key
  identity_provider_type           = var.identity_provider_type
  invocation_role                  = var.invocation_role
  logging_role                     = var.logging_role
  pre_authentication_login_banner  = var.pre_authentication_login_banner
  post_authentication_login_banner = var.post_authentication_login_banner
  protocols                        = var.protocols
  security_policy_name             = var.security_policy_name
  url                              = var.url
  tags                             = merge(var.tags, { "Name" = var.name })

  dynamic "endpoint_details" {
    for_each = var.endpoint_type == "VPC" ? [1] : []
    content {
      address_allocation_ids = var.address_allocation_ids
      security_group_ids     = var.security_group_ids
      subnet_ids             = var.subnet_ids
      vpc_endpoint_id        = var.vpc_endpoint_id
      vpc_id                 = var.vpc_id
    }
  }
  protocol_details {
    as2_transports              = var.as2_transports
    passive_ip                  = var.passive_ip
    set_stat_option             = var.set_stat_option
    tls_session_resumption_mode = var.tls_session_resumption_mode
  }
}

##############
# Create the S3 bucket(s) for the transfer family server
##############

module "bucket" {
  source = "../s3/bucket"

  bucket_prefix   = var.name
  lifecycle_rules = var.lifecycle_rules
  tags            = var.tags
}

##############
# Create the transfer family server IAM role
##############

module "transfer_family_iam_role_policy" {
  source = "../iam/policy"

  description = "Transfer Family Server IAM role policy for ${var.name}"
  name_prefix = "${var.name}-transfer-family-role-policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid = "AllowListingOfUserFolder",
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ],
        Effect   = "Allow",
        Resource = [module.bucket.s3_bucket_arn]
      },
      {
        Sid = "HomeDirObjectAccess",
        Action = [
          "s3:GetObject",
          "s3:GetObjectACL",
          "s3:GetObjectVersion",
          "s3:DeleteObject",
          "s3:DeleteObjectVersion",
          "s3:PutObject",
          "s3:PutObjectACL"
        ],
        Effect   = "Allow",
        Resource = "${module.bucket.s3_bucket_arn}/*"
      }
    ]
  })
  tags = var.tags
}

module "transfer_family_iam_role" {
  source = "../iam/role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Condition = {
          StringEquals = {
            "aws:SourceAccount": "${data.aws_caller_identity.current.account_id}"
          },
          ArnLike = {
            "aws:SourceArn": "arn:aws:transfer:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:user/*"
          }
        },
        Effect = "Allow",
        Principal = {
          Service = "transfer.amazonaws.com"
        }
      }
    ]
  })
  description = "Transfer Family Server IAM role for ${var.name}"
  name_prefix = "${var.name}-transfer-family-role"
  policy_arns = [module.transfer_family_iam_role_policy.arn]
  tags        = var.tags
}

##############
# Create the transfer family server users
##############

resource "aws_transfer_user" "this" {
  for_each = var.users

  home_directory      = each.value.home_directory
  home_directory_type = each.value.home_directory_type
  policy              = each.value.policy
  role                = module.transfer_family_iam_role.arn
  server_id           = aws_transfer_server.this.id
  tags                = var.tags
  user_name           = each.value.username

  dynamic "home_directory_mappings" {
    # Disables the dynamic block of home_directory_mappings if home_directory_type is not "LOGICAL".
    for_each = each.value.home_directory_type == "LOGICAL" ? [1] : []
    content {
      entry  = "/"
      target = "/${module.bucket.s3_bucket_id}/${each.value.username}"
    }
  }
}

##############
# Create the user SSH keys
##############

resource "aws_transfer_ssh_key" "this" {
  for_each = var.users

  server_id = aws_transfer_server.this.id
  user_name = each.value.username
  body      = each.value.public_key

  depends_on = [aws_transfer_user.this]
}

##############
# Create the transfer family server workflow
##############
