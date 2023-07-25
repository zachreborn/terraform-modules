terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0.0"
      configuration_aliases = [aws.organization_management_account, aws.organization_security_account]
    }
  }
}

# GuardDuty Detector
resource "aws_guardduty_detector" "this" {
  provider                     = aws.organization_security_account
  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency
}

# GuardDuty Admin Deligation
resource "aws_guardduty_organization_admin_account" "this" {
  depends_on = [
    aws_guardduty_detector.this
  ]
  provider         = aws.organization_management_account
  admin_account_id = var.admin_account_id
}

# GuardDuty Organization Configuration
resource "aws_guardduty_organization_configuration" "this" {
  depends_on = [
    aws_guardduty_organization_admin_account.this
  ]
  provider                         = aws.organization_security_account
  auto_enable_organization_members = var.auto_enable
  detector_id                                  = aws_guardduty_detector.this.id
  datasources {
    s3_logs {
      auto_enable = var.s3_logs_enable
    }
  }
}
