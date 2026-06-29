###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 6.0.0"
      configuration_aliases = [aws.prod_region, aws.dr_region]
    }
  }
}

###########################
# Data Sources
###########################
# The central account is the registered AWS Backup delegated administrator and can read the
# organization. The org ID scopes the cross-account vault access policy and the KMS key policy so
# only principals inside this organization can copy into / encrypt with the central vaults.
data "aws_organizations_organization" "this" {
  provider = aws.prod_region
}

###########################
# Locals
###########################
locals {
  org_id = data.aws_organizations_organization.this.id

  # central-vault-<tier>. The same name is used in both regions; the region lives in the ARN.
  central_vault_names = {
    for tkey, _ in var.backup_tiers : tkey => "${var.central_vault_prefix}${tkey}"
  }

  # Tiers that also keep a cross-region copy in the DR region.
  dr_tiers = {
    for tkey, tier in var.backup_tiers : tkey => tier if tier.copy_to_dr
  }

  policy_regions = coalesce(var.policy_regions, [var.prod_region])

  # Resource-based policy on each central vault: allow any principal in this organization to copy
  # recovery points into the vault. This is the destination half of cross-account copy.
  vault_access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowOrgCopyIntoBackupVault"
      Effect    = "Allow"
      Principal = "*"
      Action    = "backup:CopyIntoBackupVault"
      Resource  = "*"
      Condition = {
        StringEquals = {
          "aws:PrincipalOrgID" = local.org_id
        }
      }
    }]
  })

  # Key policy for every central CMK: full admin to the central account root (so the key is never
  # orphaned), plus encrypt/decrypt/grant rights to any backup role in the organization so member
  # accounts can write encrypted copies into the central vaults.
  kms_key_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnableCentralAccountKeyAdministration"
        Effect    = "Allow"
        Principal = { AWS = "arn:aws:iam::${var.central_account_id}:root" }
        Action    = "kms:*"
        Resource  = "*"
      },
      {
        Sid       = "AllowOrgBackupCopyEncryption"
        Effect    = "Allow"
        Principal = "*"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalOrgID" = local.org_id
          }
        }
      }
    ]
  })

  # ----------------------------------------------------------------------------------------------
  # BACKUP_POLICY document, derived entirely from var.backup_tiers.
  #
  # One plan per tier; one rule per tier rule. Every rule writes to the local staging vault and
  # (for non-continuous rules with central_copy) copies cross-account to the central vault in
  # prod_region, plus a second copy to dr_region for copy_to_dr tiers. Per the AWS Organizations
  # backup policy syntax every leaf value is a string wrapped in {"@@assign": ...}; the $account
  # token is substituted per member account at apply time, while the central account is a literal.
  # ----------------------------------------------------------------------------------------------
  backup_policy = {
    plans = {
      for tkey, tier in var.backup_tiers : "${var.policy_name}-tier-${tkey}" => {
        regions = { "@@assign" = local.policy_regions }
        rules = {
          for rule in tier.rules : rule.name => merge(
            {
              schedule_expression            = { "@@assign" = rule.schedule }
              start_backup_window_minutes    = { "@@assign" = tostring(rule.start_window_minutes) }
              complete_backup_window_minutes = { "@@assign" = tostring(rule.completion_window_minutes) }
              target_backup_vault_name       = { "@@assign" = var.staging_vault_name }
              lifecycle = {
                delete_after_days = { "@@assign" = tostring(rule.local_delete_after_days) }
              }
            },
            rule.continuous ? {
              enable_continuous_backup = { "@@assign" = true }
            } : {},
            # copy_actions ship the recovery point to the central vault(s). Continuous/PITR points
            # are local-only (cross-account PITR copy is not supported), so they get no copy_actions.
            (rule.central_copy && !rule.continuous) ? {
              copy_actions = merge(
                {
                  "arn:aws:backup:${var.prod_region}:${var.central_account_id}:backup-vault:${local.central_vault_names[tkey]}" = {
                    target_backup_vault_arn = { "@@assign" = "arn:aws:backup:${var.prod_region}:${var.central_account_id}:backup-vault:${local.central_vault_names[tkey]}" }
                    lifecycle = merge(
                      { delete_after_days = { "@@assign" = tostring(rule.central_delete_after_days) } },
                      rule.central_cold_after_days != null ? {
                        move_to_cold_storage_after_days = { "@@assign" = tostring(rule.central_cold_after_days) }
                      } : {}
                    )
                  }
                },
                tier.copy_to_dr ? {
                  "arn:aws:backup:${var.dr_region}:${var.central_account_id}:backup-vault:${local.central_vault_names[tkey]}" = {
                    target_backup_vault_arn = { "@@assign" = "arn:aws:backup:${var.dr_region}:${var.central_account_id}:backup-vault:${local.central_vault_names[tkey]}" }
                    lifecycle = merge(
                      { delete_after_days = { "@@assign" = tostring(rule.central_delete_after_days) } },
                      rule.central_cold_after_days != null ? {
                        move_to_cold_storage_after_days = { "@@assign" = tostring(rule.central_cold_after_days) }
                      } : {}
                    )
                  }
                } : {}
              )
            } : {}
          )
        }
        selections = {
          tags = {
            "by-${var.tag_key}" = {
              iam_role_arn = { "@@assign" = "arn:aws:iam::$account:role/${var.backup_role_name}" }
              tag_key      = { "@@assign" = var.tag_key }
              tag_value    = { "@@assign" = [tkey] }
            }
          }
        }
      }
    }
  }
}

###########################
# Central KMS Keys (prod_region)
###########################
module "central_kms_prod" {
  source   = "../../aws/kms"
  for_each = var.backup_tiers
  providers = {
    aws = aws.prod_region
  }

  name_prefix             = "${var.central_vault_prefix}${each.key}-${var.prod_region}"
  description             = "CMK for central backup vault ${each.key} (${var.prod_region})"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.kms_enable_key_rotation
  policy                  = local.kms_key_policy
  tags                    = var.tags
}

###########################
# Central KMS Keys (dr_region)
###########################
module "central_kms_dr" {
  source   = "../../aws/kms"
  for_each = local.dr_tiers
  providers = {
    aws = aws.dr_region
  }

  name_prefix             = "${var.central_vault_prefix}${each.key}-${var.dr_region}"
  description             = "CMK for central backup vault ${each.key} (${var.dr_region})"
  deletion_window_in_days = var.kms_deletion_window_in_days
  enable_key_rotation     = var.kms_enable_key_rotation
  policy                  = local.kms_key_policy
  tags                    = var.tags
}

###########################
# Central Vaults (prod_region)
###########################
resource "aws_backup_vault" "central_prod" {
  for_each = var.backup_tiers
  provider = aws.prod_region

  name        = local.central_vault_names[each.key]
  kms_key_arn = module.central_kms_prod[each.key].arn
  tags        = merge(tomap({ Name = local.central_vault_names[each.key] }), var.tags)
}

resource "aws_backup_vault_policy" "central_prod" {
  for_each = var.backup_tiers
  provider = aws.prod_region

  backup_vault_name = aws_backup_vault.central_prod[each.key].name
  policy            = local.vault_access_policy
}

resource "aws_backup_vault_lock_configuration" "central_prod" {
  for_each = var.enable_vault_lock ? var.backup_tiers : {}
  provider = aws.prod_region

  backup_vault_name   = aws_backup_vault.central_prod[each.key].name
  changeable_for_days = var.changeable_for_days
  min_retention_days  = each.value.vault_min_retention_days
}

###########################
# Central Vaults (dr_region)
###########################
resource "aws_backup_vault" "central_dr" {
  for_each = local.dr_tiers
  provider = aws.dr_region

  name        = local.central_vault_names[each.key]
  kms_key_arn = module.central_kms_dr[each.key].arn
  tags        = merge(tomap({ Name = local.central_vault_names[each.key] }), var.tags)
}

resource "aws_backup_vault_policy" "central_dr" {
  for_each = local.dr_tiers
  provider = aws.dr_region

  backup_vault_name = aws_backup_vault.central_dr[each.key].name
  policy            = local.vault_access_policy
}

resource "aws_backup_vault_lock_configuration" "central_dr" {
  for_each = var.enable_vault_lock ? local.dr_tiers : {}
  provider = aws.dr_region

  backup_vault_name   = aws_backup_vault.central_dr[each.key].name
  changeable_for_days = var.changeable_for_days
  min_retention_days  = each.value.vault_min_retention_days
}

###########################
# Organization BACKUP_POLICY
###########################
# Authored in the central (delegated administrator) account and attached to the workload OUs. AWS
# Organizations propagates it to every member account in those OUs, including accounts added later,
# with no per-account deploy.
resource "aws_organizations_policy" "tiered_backup" {
  provider = aws.prod_region

  name        = var.policy_name
  description = "Sunward tag-based tiered backup policy. Tier dimensions derived from the backup_tiers map."
  type        = "BACKUP_POLICY"
  content     = jsonencode(local.backup_policy)
  tags        = var.tags
}

resource "aws_organizations_policy_attachment" "tiered_backup" {
  for_each = toset(var.target_ou_ids)
  provider = aws.prod_region

  policy_id = aws_organizations_policy.tiered_backup.id
  target_id = each.value
}

###########################
# Audit Manager (optional)
###########################
resource "aws_backup_framework" "this" {
  count    = var.enable_audit_manager ? 1 : 0
  provider = aws.prod_region

  name        = replace("${var.policy_name}_framework", "-", "_")
  description = "Codifies the tiered backup rules for org-wide AWS Backup compliance reporting."

  # Every protected resource must be a member of a backup plan.
  control {
    name = "BACKUP_RESOURCES_PROTECTED_BY_BACKUP_PLAN"
  }

  # Recovery points must be retained for at least the tier minimum.
  control {
    name = "BACKUP_RECOVERY_POINT_MINIMUM_RETENTION_CHECK"
    input_parameter {
      name  = "requiredRetentionDays"
      value = tostring(min([for _, tier in var.backup_tiers : tier.vault_min_retention_days]...))
    }
  }

  # Recovery points must be encrypted.
  control {
    name = "BACKUP_RECOVERY_POINT_ENCRYPTED"
  }

  tags = var.tags
}

resource "aws_backup_report_plan" "this" {
  count    = var.enable_audit_manager ? 1 : 0
  provider = aws.prod_region

  name        = replace("${var.policy_name}_report", "-", "_")
  description = "Daily org-wide AWS Backup compliance report for the tiered backup framework."

  report_delivery_channel {
    s3_bucket_name = var.audit_report_s3_bucket_name
    formats        = ["CSV", "JSON"]
  }

  report_setting {
    report_template = "BACKUP_JOB_REPORT"
    accounts        = ["ALL"]
    regions         = distinct(concat([var.prod_region, var.dr_region]))
  }

  tags = var.tags

  lifecycle {
    precondition {
      condition     = !var.enable_audit_manager || var.audit_report_s3_bucket_name != null
      error_message = "audit_report_s3_bucket_name must be set when enable_audit_manager = true."
    }
  }
}
