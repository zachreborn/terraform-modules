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
resource "aws_guardduty_detector" "this" {
  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency
}
