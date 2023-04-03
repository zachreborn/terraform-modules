terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
      # configuration_aliases = [aws.organization_master_account, aws.organization_security_account]
    }
  }
}

# GuardDuty Detector
/* resource "aws_guardduty_detector" "this" {
  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency
} */

resource "aws_guardduty_organization_admin_account" "this" {
  # provider         = aws.organization_master_account
  count            = var.enable_organization ? 1 : 0
  admin_account_id = var.admin_account_id
}

# resource "aws_guardduty_organization_configuration" "this" {
#   provider    = aws.organization_security_account
#   count       = var.enable_organization ? 1 : 0
#   auto_enable = var.auto_enable
#   detector_id = aws_guardduty_detector.this.id
# }
