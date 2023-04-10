terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_iam_policy" "mfa_required" {
  name        = var.mfa_required_policy_name
  description = "Allows users to manage their own MFA settings"
  policy      = file("${path.module}/mfa_required_policy.json")
}
