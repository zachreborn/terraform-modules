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

resource "aws_guardduty_organization_configuration_feature" "ebs_malware_protection" {
  count       = var.enable_ebs_malware_protection ? 1 : 0
  auto_enable = var.guardduty_detector_auto_enable
  detector_id = aws_guardduty_detector.this.id
  name        = "EBS_MALWARE_PROTECTION"
  provider    = aws.organization_security_account
}

resource "aws_guardduty_organization_configuration_feature" "eks_audit_logs" {
  count       = var.enable_eks_audit_logs ? 1 : 0
  auto_enable = var.auto_enable_organization_members
  detector_id = aws_guardduty_detector.this.id
  name        = "EKS_AUDIT_LOGS"
  provider    = aws.organization_security_account
}

resource "aws_guardduty_organization_configuration_feature" "eks_runtime_monitoring" {
  count       = var.enable_eks_runtime_monitoring ? 1 : 0
  auto_enable = var.auto_enable_organization_members
  detector_id = aws_guardduty_detector.this.id
  name        = "EKS_RUNTIME_MONITORING"
  provider    = aws.organization_security_account
}

resource "aws_guardduty_organization_configuration_feature" "lambda_network_logs" {
  count       = var.enable_lambda_network_logs ? 1 : 0
  auto_enable = var.auto_enable_organization_members
  detector_id = aws_guardduty_detector.this.id
  name        = "LAMBDA_NETWORK_LOGS"
  provider                         = aws.organization_security_account
}

resource "aws_guardduty_organization_configuration_feature" "rds_login_events" {
  count       = var.enable_rds_login_events ? 1 : 0
  auto_enable = var.auto_enable_organization_members
  detector_id = aws_guardduty_detector.this.id
  name        = "RDS_LOGIN_EVENTS"
  provider    = aws.organization_security_account
}

resource "aws_guardduty_organization_configuration_feature" "runtime_monitoring" {
  count       = var.enable_runtime_monitoring ? 1 : 0
  auto_enable = var.auto_enable_organization_members
  detector_id = aws_guardduty_detector.this.id
  name        = "RUNTIME_MONITORING"
  provider    = aws.organization_security_account
}

resource "aws_guardduty_organization_configuration_feature" "s3_data_events" {
    count       = var.enable_s3_data_events ? 1 : 0
    auto_enable = var.auto_enable_organization_members
    detector_id = aws_guardduty_detector.this.id
    name        = "S3_DATA_EVENTS"
    provider    = aws.organization_security_account
}
