resource "aws_guardduty_detector" "this" {
  enable                       = var.enable
  finding_publishing_frequency = var.finding_publishing_frequency
}

resource "aws_guardduty_organization_admin_account" "this" {
  count            = var.enable_organization ? 1 : 0
  admin_account_id = var.admin_account_id
}

resource "aws_guardduty_organization_configuration" "this" {
  count       = var.enable_organization ? 1 : 0
  auto_enable = var.auto_enable
  detector_id = aws_guardduty_detector.this.id
}
