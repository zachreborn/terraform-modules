###############################################################
# KMS Encryption Key
###############################################################

# Production region key
resource "aws_kms_key" "prod_key" {
  provider                           = aws.prod_region
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

resource "aws_kms_alias" "prod_alias" {
  provider      = aws.prod_region
  name          = var.key_name
  target_key_id = aws_kms_key.prod_key.key_id
}

# Disaster recovery region key
resource "aws_kms_key" "dr_key" {
  provider                           = aws.dr_region
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
  provider      = aws.dr_region
  name          = var.key_name
  target_key_id = aws_kms_key.dr_key.key_id
}

###############################################################
# Backup Vaults
###############################################################

### Hourly
resource "aws_backup_vault" "vault_prod_hourly" {
  provider    = aws.prod_region
  name        = var.vault_prod_hourly_name
  kms_key_arn = aws_kms_key.prod_key.arn
  tags        = var.tags
}

### Daily
resource "aws_backup_vault" "vault_prod_daily" {
  provider    = aws.prod_region
  name        = var.vault_prod_daily_name
  kms_key_arn = aws_kms_key.prod_key.arn
  tags        = var.tags
}

### Monthly
resource "aws_backup_vault" "vault_prod_monthly" {
  provider    = aws.prod_region
  name        = var.vault_prod_monthly_name
  kms_key_arn = aws_kms_key.prod_key.arn
  tags        = var.tags
}

### Disaster Recovery
resource "aws_backup_vault" "vault_disaster_recovery" {
  provider    = aws.dr_region
  name        = var.vault_disaster_recovery_name
  kms_key_arn = aws_kms_key.dr_key.arn
  tags        = var.tags
}

###############################################################
# Backup Vault Policy
###############################################################

resource "aws_backup_vault_policy" "vault_prod_hourly" {
  provider          = aws.prod_region
  backup_vault_name = aws_backup_vault.vault_prod_hourly.name
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
      "Resource": "${aws_backup_vault.vault_prod_hourly.arn}"
    }
  ]
}
POLICY
}

resource "aws_backup_vault_policy" "vault_prod_daily" {
  provider          = aws.prod_region
  backup_vault_name = aws_backup_vault.vault_prod_daily.name
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
      "Resource": "${aws_backup_vault.vault_prod_daily.arn}"
    }
  ]
}
POLICY
}

resource "aws_backup_vault_policy" "vault_prod_monthly" {
  provider          = aws.prod_region
  backup_vault_name = aws_backup_vault.vault_prod_monthly.name
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
      "Resource": "${aws_backup_vault.vault_prod_monthly.arn}"
    }
  ]
}
POLICY
}

resource "aws_backup_vault_policy" "vault_disaster_recovery" {
  provider          = aws.dr_region
  backup_vault_name = aws_backup_vault.vault_disaster_recovery.name
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
      "Resource": "${aws_backup_vault.vault_disaster_recovery.arn}"
    }
  ]
}
POLICY
}

###############################################################
# Backup Vault Lock
###############################################################

resource "aws_backup_vault_lock_configuration" "vault_prod_hourly" {
  provider            = aws.prod_region
  backup_vault_name   = aws_backup_vault.vault_prod_hourly.name
  changeable_for_days = var.changeable_for_days
}

resource "aws_backup_vault_lock_configuration" "vault_prod_daily" {
  provider            = aws.prod_region
  backup_vault_name   = aws_backup_vault.vault_prod_daily.name
  changeable_for_days = var.changeable_for_days
}

resource "aws_backup_vault_lock_configuration" "vault_prod_monthly" {
  provider            = aws.prod_region
  backup_vault_name   = aws_backup_vault.vault_prod_monthly.name
  changeable_for_days = var.changeable_for_days
}

resource "aws_backup_vault_lock_configuration" "vault_disaster_recovery" {
  provider            = aws.dr_region
  backup_vault_name   = aws_backup_vault.vault_disaster_recovery.name
  changeable_for_days = var.changeable_for_days
}

