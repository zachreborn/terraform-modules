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
      arn = "arn:aws:kms:us-west-2:222222222222:key/11111111-1111-1111-1111-111111111111"
    }
  }
}

mock_provider "aws" {
  alias = "dr_region"

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-2:222222222222:key/22222222-2222-2222-2222-222222222222"
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
      description = "Critical"
      copy_to_dr  = true
      rules = [
        {
          name                      = "daily"
          schedule                  = "cron(0 5 * * ? *)"
          central_delete_after_days = 35
        },
      ]
    }
  }
}

run "valid_baseline_does_not_fail" {
  command = plan

  assert {
    condition     = length(aws_backup_vault.central_prod) == 1
    error_message = "Expected one central vault to plan with valid inputs."
  }
}

run "rejects_delete_less_than_cold_plus_90" {
  command = plan

  variables {
    backup_tiers = {
      "1" = {
        description = "Critical"
        copy_to_dr  = false
        rules = [
          {
            name                      = "monthly"
            schedule                  = "cron(0 5 1 * ? *)"
            central_delete_after_days = 100
            central_cold_after_days   = 30
          },
        ]
      }
    }
  }

  expect_failures = [var.backup_tiers]
}

run "rejects_vault_min_retention_above_rule_retention" {
  command = plan

  variables {
    backup_tiers = {
      "1" = {
        description              = "Critical"
        copy_to_dr               = false
        vault_min_retention_days = 60
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

  expect_failures = [var.backup_tiers]
}

run "rejects_staging_retention_days_below_1" {
  command = plan

  variables {
    staging_retention_days = 0
  }

  expect_failures = [var.staging_retention_days]
}

run "rejects_staging_retention_days_above_35" {
  command = plan

  variables {
    staging_retention_days = 36
  }

  expect_failures = [var.staging_retention_days]
}

run "rejects_invalid_central_account_id" {
  command = plan

  variables {
    central_account_id = "12345"
  }

  expect_failures = [var.central_account_id]
}

run "rejects_invalid_prod_region" {
  command = plan

  variables {
    prod_region = "uswest2"
  }

  expect_failures = [var.prod_region]
}

run "rejects_invalid_dr_region" {
  command = plan

  variables {
    dr_region = "us-east"
  }

  expect_failures = [var.dr_region]
}

run "rejects_unknown_vault_lock_mode" {
  command = plan

  variables {
    vault_lock_mode = "strict"
  }

  expect_failures = [var.vault_lock_mode]
}

run "rejects_changeable_for_days_below_3" {
  command = plan

  variables {
    changeable_for_days = 2
  }

  expect_failures = [var.changeable_for_days]
}

run "rejects_dr_retention_days_below_7" {
  command = plan

  variables {
    dr_retention_days = 6
  }

  expect_failures = [var.dr_retention_days]
}

run "rejects_kms_deletion_window_below_7" {
  command = plan

  variables {
    kms_deletion_window_in_days = 6
  }

  expect_failures = [var.kms_deletion_window_in_days]
}

run "rejects_kms_deletion_window_above_30" {
  command = plan

  variables {
    kms_deletion_window_in_days = 31
  }

  expect_failures = [var.kms_deletion_window_in_days]
}

run "rejects_audit_manager_without_report_bucket" {
  command = plan

  variables {
    enable_audit_manager = true
  }

  expect_failures = [aws_backup_report_plan.this]
}

# Do NOT delete, skip, or loosen an `expect_failures` case (or any assertion above) just to
# make `tofu test` pass. A validation test that unexpectedly fails means either the
# `validation {}` block in variables.tf has a bug or the test's inputs are wrong — find and
# fix the root cause, then re-run `tofu test` until it passes for the right reason.
