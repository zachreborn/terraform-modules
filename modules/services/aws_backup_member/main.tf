###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Locals
###########################
locals {
  # Trust policy: allow the AWS Backup service to assume this role.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAWSBackupAssumeRole"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })

  # Identity-side permissions for cross-account copy into the central account. The central vault's
  # resource policy grants the org backup:CopyIntoBackupVault; this is the matching identity grant,
  # plus the KMS rights needed to write copies encrypted under the central account's CMKs. Scoped to
  # the central account's vault and key ARNs.
  cross_account_copy_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CopyIntoCentralBackupVaults"
        Effect = "Allow"
        Action = [
          "backup:CopyIntoBackupVault",
          "backup:CopyFromBackupVault"
        ]
        Resource = "arn:aws:backup:*:${var.central_account_id}:backup-vault:*"
      },
      {
        Sid    = "UseCentralBackupKMSKeys"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:CreateGrant"
        ]
        Resource = "arn:aws:kms:*:${var.central_account_id}:key/*"
      }
    ]
  })
}

###########################
# Staging Vault
###########################
# Local, tier-agnostic vault. AWS Backup always writes recovery points here first; copy_actions in
# the org BACKUP_POLICY then ship them cross-account to the central vaults. Disposable: no lock,
# short retention (governed by the policy's local_delete_after_days).
resource "aws_backup_vault" "staging" {
  name          = var.staging_vault_name
  kms_key_arn   = var.staging_kms_key_arn
  force_destroy = var.staging_vault_force_destroy
  tags          = merge(tomap({ Name = var.staging_vault_name }), var.tags)
}

###########################
# Backup IAM Role
###########################
module "backup_role" {
  source = "../../aws/iam/role"

  name                 = var.backup_role_name
  path                 = var.backup_role_path
  permissions_boundary = var.backup_role_permissions_boundary
  assume_role_policy   = local.assume_role_policy
  policy_arns          = var.managed_policy_arns
  tags                 = var.tags
}

# Inline policy: cross-account copy + KMS rights on the central account. Kept inline (same IAM
# domain as the role) because it depends on the per-account central_account_id.
resource "aws_iam_role_policy" "cross_account_copy" {
  name   = "central-backup-copy"
  role   = module.backup_role.name
  policy = local.cross_account_copy_policy
}
