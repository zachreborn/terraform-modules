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
  auto_enable_organization_members = var.auto_enable_organization_members
  detector_id                      = aws_guardduty_detector.this.id
}

locals {
  guardduty_detectors = {
    ebs_malware_protection = var.enable_ebs_malware_protection
    eks_audit_logs         = var.enable_eks_audit_logs
    eks_runtime_monitoring = var.enable_eks_runtime_monitoring
    lambda_network_logs    = var.enable_lambda_network_logs
    rds_login_events       = var.enable_rds_login_events
    runtime_monitoring     = var.enable_runtime_monitoring
    s3_data_events         = var.enable_s3_data_events
  }

  enabled_detectors = { for key, enabled in local.guardduty_detectors : upper(key) => enabled if enabled }
}

resource "aws_guardduty_organization_configuration_feature" "this" {
  for_each    = local.enabled_detectors
  auto_enable = var.auto_enable_organization_members
  detector_id = aws_guardduty_detector.this.id
  name        = each.key
  provider    = aws.organization_security_account
}
