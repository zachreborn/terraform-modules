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

  # Trust policy for the central account's AWS Backup role.
  central_backup_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAWSBackupAssumeRole"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })

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
  # One plan per tier; one rule per tier rule. Every rule writes to the local staging vault (kept
  # staging_retention_days, matching the staging vault's lock floor) and
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
                delete_after_days = { "@@assign" = tostring(var.staging_retention_days) }
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
                      (var.dr_cold_storage && rule.central_cold_after_days != null) ? {
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
# Central Backup IAM Role
###########################
# Role AWS Backup assumes for jobs started in the central account: copying a recovery point from a
# central vault back into a member account's staging vault, and restores run in the central account.
module "central_backup_role" {
  source = "../../aws/iam/role"
  providers = {
    aws = aws.prod_region
  }

  name                 = var.central_backup_role_name
  path                 = var.central_backup_role_path
  permissions_boundary = var.central_backup_role_permissions_boundary
  assume_role_policy   = local.central_backup_assume_role_policy
  policy_arns          = var.central_backup_role_policy_arns
  tags                 = var.tags
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
# Central Vaults (prod_region)
###########################
resource "aws_backup_vault" "central_prod" {
  for_each = var.backup_tiers
  provider = aws.prod_region

  kms_key_arn = module.central_kms_prod[each.key].arn
  name        = local.central_vault_names[each.key]
  tags        = merge(tomap({ Name = local.central_vault_names[each.key] }), var.tags)
}

resource "aws_backup_vault_policy" "central_prod" {
  for_each = var.backup_tiers
  provider = aws.prod_region

  backup_vault_name = aws_backup_vault.central_prod[each.key].name
  policy            = local.vault_access_policy
}

resource "aws_backup_vault_lock_configuration" "central_prod" {
  for_each = var.vault_lock_mode != "none" ? var.backup_tiers : {}
  provider = aws.prod_region

  backup_vault_name   = aws_backup_vault.central_prod[each.key].name
  changeable_for_days = var.vault_lock_mode == "compliance" ? var.changeable_for_days : null
  min_retention_days  = each.value.vault_min_retention_days
}

###########################
# Central Vaults (dr_region)
###########################
# Logically air-gapped vaults: always compliance-locked, encrypted with an AWS-owned key, and
# shareable through AWS RAM so member accounts can restore from them directly.
resource "aws_backup_logically_air_gapped_vault" "central_dr" {
  for_each = local.dr_tiers
  provider = aws.dr_region

  name               = local.central_vault_names[each.key]
  min_retention_days = each.value.vault_min_retention_days
  max_retention_days = max([for rule in each.value.rules : rule.central_delete_after_days]...)
  tags               = merge(tomap({ Name = local.central_vault_names[each.key] }), var.tags)
}

resource "aws_backup_vault_policy" "central_dr" {
  for_each = local.dr_tiers
  provider = aws.dr_region

  backup_vault_name = aws_backup_logically_air_gapped_vault.central_dr[each.key].name
  policy            = local.vault_access_policy
}

###########################
# DR Vault Sharing (AWS RAM)
###########################
resource "aws_ram_resource_share" "central_dr" {
  count    = var.share_dr_vaults_with_target_ous && length(local.dr_tiers) > 0 ? 1 : 0
  provider = aws.dr_region

  name                      = "${var.central_vault_prefix}dr"
  allow_external_principals = false
  tags                      = var.tags
}

resource "aws_ram_resource_association" "central_dr" {
  for_each = var.share_dr_vaults_with_target_ous ? local.dr_tiers : {}
  provider = aws.dr_region

  resource_arn       = aws_backup_logically_air_gapped_vault.central_dr[each.key].arn
  resource_share_arn = aws_ram_resource_share.central_dr[0].arn
}

resource "aws_ram_principal_association" "central_dr" {
  for_each = var.share_dr_vaults_with_target_ous && length(local.dr_tiers) > 0 ? toset(var.target_ou_ids) : toset([])
  provider = aws.dr_region

  principal          = "arn:aws:organizations::${data.aws_organizations_organization.this.master_account_id}:ou/${local.org_id}/${each.value}"
  resource_share_arn = aws_ram_resource_share.central_dr[0].arn
}

###########################
# Organization BACKUP_POLICY
###########################
# Authored in the central (delegated administrator) account and attached to the workload OUs. AWS
# Organizations propagates it to every member account in those OUs, including accounts added later,
# with no per-account deploy.
resource "aws_organizations_policy" "tiered_backup" {
  provider = aws.prod_region

  content     = jsonencode(local.backup_policy)
  description = "Tag-based tiered backup policy. Tier dimensions derived from the backup_tiers map."
  name        = var.policy_name
  type        = "BACKUP_POLICY"
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
