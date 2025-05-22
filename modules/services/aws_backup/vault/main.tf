###############################################################
# AWS Backup Vault and Configuration
###############################################################

resource "aws_backup_vault" "this" {
  provider    = aws.aws_prod_region
  name        = var.name
  kms_key_arn = var.kms_key_arn
  tags        = var.tags
}

resource "aws_backup_vault_lock_configuration" "this" {
  count               = var.enable_vault_lock ? 1 : 0
  provider            = aws.aws_prod_region
  backup_vault_name   = aws_backup_vault.this.name
  changeable_for_days = var.changeable_for_days
}

###############################################################
# Backup Vault Policy
###############################################################

resource "aws_backup_vault_policy" "this" {
  provider          = aws.aws_prod_region
  backup_vault_name = aws_backup_vault.this.name
  policy            = <<POLICY
{
  "Version": "2012-10-17",
  "Id": "default",
  "Statement": [
    {
      "Sid": "deny_all_delete",
      "Effect": "Deny",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "backup:DeleteBackupVault",
        "backup:DeleteRecoveryPoint",
        "backup:UpdateRecoveryPointLifecycle"
      ],
      "Resource": "${aws_backup_vault.this.arn}"
    }
  ]
}
POLICY
}

###############################################################
# KMS Encryption Key
###############################################################

# Production region key
resource "aws_kms_key" "key" {
  provider                           = aws.aws_prod_region
  bypass_policy_lockout_safety_check = var.key_bypass_policy_lockout_safety_check
  customer_master_key_spec           = var.key_customer_master_key_spec
  description                        = var.key_description
  deletion_window_in_days            = var.key_deletion_window_in_days
  enable_key_rotation                = var.key_enable_key_rotation
  key_usage                          = var.key_usage
  is_enabled                         = var.key_is_enabled
  policy                             = var.key_policy
  tags                               = var.tags
}

resource "aws_kms_alias" "alias" {
  provider      = aws.aws_prod_region
  name          = var.key_name
  target_key_id = aws_kms_key.key.key_id
}

# Disaster recovery region key
resource "aws_kms_key" "dr_key" {
  provider                           = aws.aws_dr_region
  bypass_policy_lockout_safety_check = var.key_bypass_policy_lockout_safety_check
  customer_master_key_spec           = var.key_customer_master_key_spec
  description                        = var.key_description
  deletion_window_in_days            = var.key_deletion_window_in_days
  enable_key_rotation                = var.key_enable_key_rotation
  key_usage                          = var.key_usage
  is_enabled                         = var.key_is_enabled
  policy                             = var.key_policy
  tags                               = var.tags
}

resource "aws_kms_alias" "dr_alias" {
  provider      = aws.aws_dr_region
  name          = var.key_name
  target_key_id = aws_kms_key.dr_key.key_id
}
