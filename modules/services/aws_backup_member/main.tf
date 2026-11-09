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
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowAWSBackupAssumeRole"
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "backup.amazonaws.com" }
    }]
  })

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

  staging_vault_access_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AllowCentralAccountCopyIntoStagingVault"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${var.central_account_id}:root" }
      Action    = "backup:CopyIntoBackupVault"
      Resource  = "*"
    }]
  })
}

###########################
# Staging Vault
###########################
resource "aws_backup_vault" "staging" {
  force_destroy = var.staging_vault_force_destroy
  kms_key_arn   = var.staging_kms_key_arn
  name          = var.staging_vault_name
  tags          = merge(tomap({ Name = var.staging_vault_name }), var.tags)
}

resource "aws_backup_vault_lock_configuration" "staging" {
  count = var.vault_lock_mode != "none" ? 1 : 0

  backup_vault_name   = aws_backup_vault.staging.name
  changeable_for_days = var.vault_lock_mode == "compliance" ? var.changeable_for_days : null
  min_retention_days  = var.staging_retention_days
  max_retention_days  = var.staging_max_retention_days
}

resource "aws_backup_vault_policy" "staging" {
  backup_vault_name = aws_backup_vault.staging.name
  policy            = local.staging_vault_access_policy
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

resource "aws_iam_role_policy" "cross_account_copy" {
  name   = "central-backup-copy"
  role   = module.backup_role.name
  policy = local.cross_account_copy_policy
}
