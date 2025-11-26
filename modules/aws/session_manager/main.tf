# Terraform module which creates Session Manager resources on AWS.
#
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html

# SSM Document
#
# https://docs.aws.amazon.com/systems-manager/latest/userguide/getting-started-configure-preferences-cli.html

# https://www.terraform.io/docs/providers/aws/r/ssm_document.html

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_ssm_document" "default" {
  name            = var.ssm_document_name
  document_type   = "Session"
  document_format = "JSON"
  tags            = merge({ "Name" = var.ssm_document_name }, var.tags)

  content = jsonencode({
    schemaVersion = "1.0"
    description   = "Document to hold regional settings for Session Manager"
    sessionType   = "Standard_Stream"
    inputs = {
      s3BucketName                = var.s3_bucket_name
      s3KeyPrefix                 = var.s3_key_prefix
      s3EncryptionEnabled         = var.s3_encryption_enabled
      cloudWatchLogGroupName      = var.cloudwatch_log_group_name
      cloudWatchEncryptionEnabled = var.cloudwatch_encryption_enabled
    }
  })
}

# Session Manager IAM Instance Profile
#
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-instance-profile.html
# https://www.terraform.io/docs/providers/aws/r/iam_instance_profile.html
resource "aws_iam_instance_profile" "default" {
  name = "${var.name}-role"
  role = aws_iam_role.default.name
  path = var.iam_path
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

module "ssm_iam_role" {
  source = "../iam/role"

  name_prefix           = "${var.name}-role-"
  assume_role_policy    = data.aws_iam_policy_document.assume_role_policy.json
  description           = "IAM Role for Session Manager"
  force_detach_policies = true
  path                  = var.iam_path
  policy_arns           = var.policy_arns
  tags                  = var.tags
}
