mock_provider "aws" {
  mock_resource "aws_backup_vault" {
    defaults = {
      arn = "arn:aws:backup:us-west-2:111111111111:backup-vault:backup-staging"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::111111111111:role/AWSBackupServiceRole"
    }
  }
}

variables {
  central_account_id = "222222222222"
}

###########################
# Baseline
###########################
run "baseline_defaults" {
  command = apply

  assert {
    condition     = aws_backup_vault.staging.name == "backup-staging"
    error_message = "Staging vault should default to backup-staging."
  }

  assert {
    condition     = aws_backup_vault.staging.force_destroy == false
    error_message = "Staging vault force_destroy should default to false."
  }

  assert {
    condition     = length(aws_backup_vault_lock_configuration.staging) == 0
    error_message = "No Vault Lock should be created when vault_lock_mode = none."
  }

  assert {
    condition     = module.backup_role.name == "AWSBackupServiceRole"
    error_message = "Backup role should default to AWSBackupServiceRole."
  }

  assert {
    condition     = aws_iam_role_policy.cross_account_copy.role == "AWSBackupServiceRole"
    error_message = "Cross-account copy policy should attach to the backup role."
  }

  assert {
    condition     = output.staging_vault_name == "backup-staging"
    error_message = "staging_vault_name output should match the vault name."
  }

  assert {
    condition     = output.staging_vault_arn == "arn:aws:backup:us-west-2:111111111111:backup-vault:backup-staging"
    error_message = "staging_vault_arn output should be the staging vault ARN."
  }

  assert {
    condition     = output.backup_role_name == "AWSBackupServiceRole"
    error_message = "backup_role_name output should match the role name."
  }

  assert {
    condition     = output.backup_role_arn == "arn:aws:iam::111111111111:role/AWSBackupServiceRole"
    error_message = "backup_role_arn output should be the backup role ARN."
  }

  assert {
    condition     = output.vault_lock_mode == "none"
    error_message = "vault_lock_mode output should default to none."
  }
}

###########################
# Central Account Wiring
###########################
run "central_account_id_scopes_policies" {
  command = plan

  assert {
    condition     = jsondecode(aws_iam_role_policy.cross_account_copy.policy).Statement[0].Resource == "arn:aws:backup:*:222222222222:backup-vault:*"
    error_message = "Copy statement should be scoped to the central account's vaults."
  }

  assert {
    condition     = jsondecode(aws_iam_role_policy.cross_account_copy.policy).Statement[1].Resource == "arn:aws:kms:*:222222222222:key/*"
    error_message = "KMS statement should be scoped to the central account's keys."
  }

  assert {
    condition     = jsondecode(output.staging_vault_policy).Statement[0].Principal.AWS == "arn:aws:iam::222222222222:root"
    error_message = "Staging vault policy should allow the central account to copy in."
  }

  assert {
    condition     = jsondecode(output.staging_vault_policy).Statement[0].Action == "backup:CopyIntoBackupVault"
    error_message = "Staging vault policy should grant only backup:CopyIntoBackupVault."
  }
}

###########################
# Vault Lock Modes
###########################
run "lock_governance" {
  command = plan

  variables {
    vault_lock_mode            = "governance"
    staging_retention_days     = 14
    staging_max_retention_days = 35
    changeable_for_days        = 7
  }

  assert {
    condition     = length(aws_backup_vault_lock_configuration.staging) == 1
    error_message = "Governance mode should create a Vault Lock."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.staging[0].changeable_for_days == null
    error_message = "changeable_for_days should be null outside compliance mode."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.staging[0].min_retention_days == 14
    error_message = "Lock min_retention_days should equal staging_retention_days."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.staging[0].max_retention_days == 35
    error_message = "Lock max_retention_days should equal staging_max_retention_days."
  }

  assert {
    condition     = output.vault_lock_mode == "governance"
    error_message = "vault_lock_mode output should be governance."
  }
}

run "lock_compliance" {
  command = plan

  variables {
    vault_lock_mode     = "compliance"
    changeable_for_days = 7
  }

  assert {
    condition     = length(aws_backup_vault_lock_configuration.staging) == 1
    error_message = "Compliance mode should create a Vault Lock."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.staging[0].changeable_for_days == 7
    error_message = "changeable_for_days should pass through in compliance mode."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.staging[0].min_retention_days == 10
    error_message = "Lock min_retention_days should default to 10."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.staging[0].max_retention_days == null
    error_message = "Lock max_retention_days should default to null."
  }

  assert {
    condition     = output.vault_lock_mode == "compliance"
    error_message = "vault_lock_mode output should be compliance."
  }
}
