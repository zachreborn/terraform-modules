mock_provider "aws" {
  alias = "prod_region"

  mock_data "aws_organizations_organization" {
    defaults = {
      id                = "o-abc123def4"
      master_account_id = "333333333333"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-west-2:222222222222:key/11111111-1111-1111-1111-111111111111"
      key_id = "11111111-1111-1111-1111-111111111111"
    }
  }

  mock_resource "aws_backup_vault" {
    defaults = {
      arn = "arn:aws:backup:us-west-2:222222222222:backup-vault:central-vault"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::222222222222:role/AWSBackupCentralRole"
    }
  }

  mock_resource "aws_organizations_policy" {
    defaults = {
      id  = "p-abcd1234"
      arn = "arn:aws:organizations::333333333333:policy/o-abc123def4/backup_policy/p-abcd1234"
    }
  }

  mock_resource "aws_backup_framework" {
    defaults = {
      arn = "arn:aws:backup:us-west-2:222222222222:framework:tiered_backup_framework"
    }
  }

  mock_resource "aws_backup_report_plan" {
    defaults = {
      arn = "arn:aws:backup:us-west-2:222222222222:report-plan:tiered_backup_report"
    }
  }
}

mock_provider "aws" {
  alias = "dr_region"

  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-2:222222222222:key/22222222-2222-2222-2222-222222222222"
      key_id = "22222222-2222-2222-2222-222222222222"
    }
  }

  mock_resource "aws_backup_logically_air_gapped_vault" {
    defaults = {
      arn = "arn:aws:backup:us-east-2:222222222222:backup-vault:central-vault-1"
    }
  }

  mock_resource "aws_ram_resource_share" {
    defaults = {
      arn = "arn:aws:ram:us-east-2:222222222222:resource-share/33333333-3333-3333-3333-333333333333"
    }
  }
}

variables {
  central_account_id = "222222222222"
  target_ou_ids      = ["ou-abcd-11111111"]
  backup_tiers = {
    "1" = {
      description              = "Critical"
      copy_to_dr               = true
      vault_min_retention_days = 7
      rules = [
        {
          name                      = "hourly"
          schedule                  = "cron(0 * * * ? *)"
          central_delete_after_days = 35
        },
        {
          name                      = "pitr"
          schedule                  = "cron(0 5 * * ? *)"
          continuous                = true
          central_delete_after_days = 35
        },
        {
          name                      = "monthly"
          schedule                  = "cron(0 5 1 * ? *)"
          central_delete_after_days = 365
          central_cold_after_days   = 30
        },
      ]
    }
    "2" = {
      description = "Standard"
      copy_to_dr  = false
      rules = [
        {
          name                      = "daily"
          schedule                  = "cron(0 5 * * ? *)"
          central_delete_after_days = 30
        },
        {
          name                      = "local"
          schedule                  = "cron(0 6 * * ? *)"
          central_copy              = false
          central_delete_after_days = 30
        },
      ]
    }
  }
}

run "baseline_defaults" {
  command = apply

  assert {
    condition     = length(aws_backup_vault.central_prod) == 2 && length(module.central_kms_prod) == 2
    error_message = "Expected one prod_region vault and CMK per tier."
  }

  assert {
    condition     = keys(aws_backup_logically_air_gapped_vault.central_dr) == ["1"] && keys(module.central_kms_dr) == ["1"]
    error_message = "Expected DR vaults and CMKs only for copy_to_dr tiers."
  }

  assert {
    condition     = aws_backup_logically_air_gapped_vault.central_dr["1"].min_retention_days == 30 && aws_backup_logically_air_gapped_vault.central_dr["1"].max_retention_days == 30
    error_message = "DR vault min and max retention should both equal dr_retention_days."
  }

  assert {
    condition     = length(aws_backup_vault_lock_configuration.central_prod) == 0
    error_message = "No Vault Lock should be created when vault_lock_mode = none."
  }

  assert {
    condition     = length(aws_ram_resource_share.central_dr) == 1 && length(aws_ram_resource_association.central_dr) == 1 && length(aws_ram_principal_association.central_dr) == 1
    error_message = "DR vaults should be shared with target_ou_ids by default."
  }

  assert {
    condition     = length(aws_backup_framework.this) == 0 && length(aws_backup_report_plan.this) == 0
    error_message = "Audit Manager resources should not be created by default."
  }

  assert {
    condition     = aws_organizations_policy.tiered_backup.type == "BACKUP_POLICY" && aws_organizations_policy.tiered_backup.name == "tiered-backup"
    error_message = "Expected a BACKUP_POLICY named tiered-backup."
  }

  assert {
    condition     = output.central_vault_names == { "1" = "central-vault-1", "2" = "central-vault-2" }
    error_message = "central_vault_names should map each tier to central-vault-<tier>."
  }

  assert {
    condition     = keys(output.central_vault_arns_prod) == ["1", "2"] && output.central_vault_arns_prod["1"] == "arn:aws:backup:us-west-2:222222222222:backup-vault:central-vault"
    error_message = "central_vault_arns_prod should map each tier to its vault ARN."
  }

  assert {
    condition     = output.central_vault_arns_dr == { "1" = "arn:aws:backup:us-east-2:222222222222:backup-vault:central-vault-1" }
    error_message = "central_vault_arns_dr should contain only copy_to_dr tiers."
  }

  assert {
    condition     = output.central_kms_key_arns_prod["2"] == "arn:aws:kms:us-west-2:222222222222:key/11111111-1111-1111-1111-111111111111"
    error_message = "central_kms_key_arns_prod should map each tier to its CMK ARN."
  }

  assert {
    condition     = output.central_kms_key_arns_dr == { "1" = "arn:aws:kms:us-east-2:222222222222:key/22222222-2222-2222-2222-222222222222" }
    error_message = "central_kms_key_arns_dr should contain only copy_to_dr tiers."
  }

  assert {
    condition     = output.dr_vault_resource_share_arn == "arn:aws:ram:us-east-2:222222222222:resource-share/33333333-3333-3333-3333-333333333333"
    error_message = "dr_vault_resource_share_arn should be the RAM share ARN."
  }

  assert {
    condition     = output.backup_policy_id == "p-abcd1234" && output.backup_policy_arn == "arn:aws:organizations::333333333333:policy/o-abc123def4/backup_policy/p-abcd1234"
    error_message = "backup_policy_id and backup_policy_arn should come from the org policy."
  }

  assert {
    condition     = output.attached_ou_ids == ["ou-abcd-11111111"]
    error_message = "attached_ou_ids should list the target OUs."
  }

  assert {
    condition     = output.central_backup_role_name == "AWSBackupCentralRole" && output.central_backup_role_arn == "arn:aws:iam::222222222222:role/AWSBackupCentralRole"
    error_message = "Central backup role outputs should match the role."
  }

  assert {
    condition     = output.vault_lock_mode == "none"
    error_message = "vault_lock_mode output should default to none."
  }

  assert {
    condition     = output.audit_framework_arn == null && output.audit_report_plan_arn == null
    error_message = "Audit Manager outputs should be null by default."
  }
}

run "policy_document" {
  command = plan

  assert {
    condition     = keys(jsondecode(output.backup_policy_json).plans) == ["tiered-backup-tier-1", "tiered-backup-tier-2"]
    error_message = "Expected one plan per tier."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].regions["@@assign"] == ["us-west-2"]
    error_message = "Plans should default to prod_region only."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.target_backup_vault_name["@@assign"] == "backup-staging"
    error_message = "Every rule should target the staging vault."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.lifecycle.delete_after_days["@@assign"] == "10"
    error_message = "Local lifecycle should equal staging_retention_days."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.start_backup_window_minutes["@@assign"] == "60" && jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.complete_backup_window_minutes["@@assign"] == "1440"
    error_message = "Backup windows should default to 60 and 1440 minutes."
  }

  assert {
    condition = keys(jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.copy_actions) == [
      "arn:aws:backup:us-east-2:222222222222:backup-vault:central-vault-1",
      "arn:aws:backup:us-west-2:222222222222:backup-vault:central-vault-1",
    ]
    error_message = "copy_to_dr tier rules should copy to both the prod_region and dr_region central vaults."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.copy_actions["arn:aws:backup:us-west-2:222222222222:backup-vault:central-vault-1"].lifecycle.delete_after_days["@@assign"] == "35"
    error_message = "Central copy lifecycle should equal central_delete_after_days."
  }

  assert {
    condition     = !contains(keys(jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.copy_actions["arn:aws:backup:us-west-2:222222222222:backup-vault:central-vault-1"].lifecycle), "move_to_cold_storage_after_days")
    error_message = "No cold transition should be emitted when central_cold_after_days is null."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly.copy_actions["arn:aws:backup:us-east-2:222222222222:backup-vault:central-vault-1"].lifecycle.delete_after_days["@@assign"] == "30"
    error_message = "DR copy lifecycle should equal dr_retention_days."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.monthly.copy_actions["arn:aws:backup:us-west-2:222222222222:backup-vault:central-vault-1"].lifecycle.move_to_cold_storage_after_days["@@assign"] == "30"
    error_message = "Central copy should carry the cold transition when central_cold_after_days is set."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.pitr.enable_continuous_backup["@@assign"] == true
    error_message = "Continuous rules should enable continuous backup."
  }

  assert {
    condition     = !contains(keys(jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.pitr), "copy_actions")
    error_message = "Continuous rules should emit no copy_actions."
  }

  assert {
    condition     = !contains(keys(jsondecode(output.backup_policy_json).plans["tiered-backup-tier-1"].rules.hourly), "enable_continuous_backup")
    error_message = "Non-continuous rules should not enable continuous backup."
  }

  assert {
    condition     = keys(jsondecode(output.backup_policy_json).plans["tiered-backup-tier-2"].rules.daily.copy_actions) == ["arn:aws:backup:us-west-2:222222222222:backup-vault:central-vault-2"]
    error_message = "Tiers without copy_to_dr should copy to the prod_region central vault only."
  }

  assert {
    condition     = !contains(keys(jsondecode(output.backup_policy_json).plans["tiered-backup-tier-2"].rules.local), "copy_actions")
    error_message = "Rules with central_copy = false should emit no copy_actions."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-2"].selections.tags["by-backup-tier"].tag_value["@@assign"] == ["2"]
    error_message = "Each plan should select resources tagged with its tier key."
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-2"].selections.tags["by-backup-tier"].iam_role_arn["@@assign"] == "arn:aws:iam::$account:role/AWSBackupServiceRole"
    error_message = "Selections should use the member backup role via the $account token."
  }
}

run "policy_regions_override" {
  command = plan

  variables {
    policy_regions = ["us-west-2", "us-east-1"]
  }

  assert {
    condition     = jsondecode(output.backup_policy_json).plans["tiered-backup-tier-2"].regions["@@assign"] == ["us-west-2", "us-east-1"]
    error_message = "Plans should deploy to policy_regions when set."
  }
}

run "lock_governance" {
  command = plan

  variables {
    vault_lock_mode     = "governance"
    changeable_for_days = 7
  }

  assert {
    condition     = length(aws_backup_vault_lock_configuration.central_prod) == 2
    error_message = "Governance mode should lock every prod_region central vault."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.central_prod["1"].changeable_for_days == null
    error_message = "changeable_for_days should be null outside compliance mode."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.central_prod["1"].min_retention_days == 7 && aws_backup_vault_lock_configuration.central_prod["2"].min_retention_days == 30
    error_message = "Lock min_retention_days should equal each tier's vault_min_retention_days."
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
    condition     = length(aws_backup_vault_lock_configuration.central_prod) == 2
    error_message = "Compliance mode should lock every prod_region central vault."
  }

  assert {
    condition     = aws_backup_vault_lock_configuration.central_prod["2"].changeable_for_days == 7
    error_message = "changeable_for_days should pass through in compliance mode."
  }

  assert {
    condition     = output.vault_lock_mode == "compliance"
    error_message = "vault_lock_mode output should be compliance."
  }
}

run "dr_sharing_disabled" {
  command = apply

  variables {
    share_dr_vaults_with_target_ous = false
  }

  assert {
    condition     = length(aws_ram_resource_share.central_dr) == 0 && length(aws_ram_resource_association.central_dr) == 0 && length(aws_ram_principal_association.central_dr) == 0
    error_message = "No RAM resources should be created when sharing is off."
  }

  assert {
    condition     = length(aws_backup_logically_air_gapped_vault.central_dr) == 1
    error_message = "DR vaults should still be created when sharing is off."
  }

  assert {
    condition     = output.dr_vault_resource_share_arn == null
    error_message = "dr_vault_resource_share_arn should be null when sharing is off."
  }
}

run "no_dr_tiers" {
  command = plan

  variables {
    backup_tiers = {
      "2" = {
        description = "Standard"
        copy_to_dr  = false
        rules = [
          {
            name                      = "daily"
            schedule                  = "cron(0 5 * * ? *)"
            central_delete_after_days = 30
          },
        ]
      }
    }
  }

  assert {
    condition     = length(aws_backup_logically_air_gapped_vault.central_dr) == 0 && length(module.central_kms_dr) == 0
    error_message = "No DR vaults or CMKs should be created without copy_to_dr tiers."
  }

  assert {
    condition     = length(aws_ram_resource_share.central_dr) == 0 && length(aws_ram_principal_association.central_dr) == 0
    error_message = "No RAM share should be created without copy_to_dr tiers, even with sharing on."
  }
}

run "audit_manager_enabled" {
  command = apply

  variables {
    enable_audit_manager        = true
    audit_report_s3_bucket_name = "backup-audit-reports"
  }

  assert {
    condition     = aws_backup_framework.this[0].name == "tiered_backup_framework"
    error_message = "Framework name should be policy_name with underscores."
  }

  assert {
    condition = toset([for c in aws_backup_framework.this[0].control : c.name]) == toset([
      "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN",
      "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK",
      "BACKUP_RECOVERY_POINT_ENCRYPTED",
    ])
    error_message = "Framework should carry the protected, minimum-retention, and encrypted controls."
  }

  assert {
    condition     = one([for c in aws_backup_framework.this[0].control : one(c.input_parameter).value if c.name == "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"]) == "7"
    error_message = "Minimum retention control should use the smallest vault_min_retention_days."
  }

  assert {
    condition     = aws_backup_report_plan.this[0].name == "tiered_backup_report" && aws_backup_report_plan.this[0].report_delivery_channel[0].s3_bucket_name == "backup-audit-reports"
    error_message = "Report plan should deliver to audit_report_s3_bucket_name."
  }

  assert {
    condition     = aws_backup_report_plan.this[0].report_setting[0].regions == toset(["us-west-2", "us-east-2"])
    error_message = "Report plan should cover prod_region and dr_region."
  }

  assert {
    condition     = output.audit_framework_arn == "arn:aws:backup:us-west-2:222222222222:framework:tiered_backup_framework" && output.audit_report_plan_arn == "arn:aws:backup:us-west-2:222222222222:report-plan:tiered_backup_report"
    error_message = "Audit Manager outputs should be the framework and report plan ARNs."
  }
}

run "wiring" {
  command = apply

  assert {
    condition     = aws_backup_vault.central_prod["1"].kms_key_arn == module.central_kms_prod["1"].arn
    error_message = "prod_region vaults should be encrypted with their tier CMK."
  }

  assert {
    condition     = aws_backup_logically_air_gapped_vault.central_dr["1"].encryption_key_arn == module.central_kms_dr["1"].arn
    error_message = "DR vaults should be encrypted with their tier CMK."
  }

  assert {
    condition     = jsondecode(aws_backup_vault_policy.central_prod["1"].policy).Statement[0].Condition.StringEquals["aws:PrincipalOrgID"] == "o-abc123def4"
    error_message = "Central vault policy should be scoped to the organization ID."
  }

  assert {
    condition     = jsondecode(aws_backup_vault_policy.central_dr["1"].policy).Statement[0].Action == "backup:CopyIntoBackupVault"
    error_message = "DR vault policy should grant backup:CopyIntoBackupVault."
  }

  assert {
    condition     = jsondecode(local.kms_key_policy).Statement[0].Principal.AWS == "arn:aws:iam::222222222222:root"
    error_message = "KMS key policy should grant administration to the central account root."
  }

  assert {
    condition     = jsondecode(local.kms_key_policy).Statement[1].Condition.StringEquals["aws:PrincipalOrgID"] == "o-abc123def4"
    error_message = "KMS key policy encrypt grant should be scoped to the organization ID."
  }

  assert {
    condition     = aws_ram_principal_association.central_dr["ou-abcd-11111111"].principal == "arn:aws:organizations::333333333333:ou/o-abc123def4/ou-abcd-11111111"
    error_message = "RAM principal should be the target OU ARN."
  }

  assert {
    condition     = aws_organizations_policy_attachment.tiered_backup["ou-abcd-11111111"].policy_id == "p-abcd1234"
    error_message = "Policy attachment should reference the org BACKUP_POLICY."
  }

  assert {
    condition     = aws_organizations_policy.tiered_backup.content == output.backup_policy_json
    error_message = "Org policy content should be the rendered BACKUP_POLICY document."
  }

  assert {
    condition     = module.central_backup_role.name == "AWSBackupCentralRole"
    error_message = "Central backup role should default to AWSBackupCentralRole."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
