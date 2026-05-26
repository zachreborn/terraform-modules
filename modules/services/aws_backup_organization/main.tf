terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

###############################################################
# Data Sources - Organization Management
###############################################################

# Get current account info (should be backup management account)
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# Get all organization accounts
data "aws_organizations_organization" "current" {}

data "aws_organizations_accounts" "all" {}

# Filter active accounts only
locals {
  active_accounts = [
    for account in data.aws_organizations_accounts.all.accounts : account
    if account.status == "ACTIVE"
  ]

  # Create account-region combinations for vault deployment
  account_regions = flatten([
    for account in local.active_accounts : [
      {
        account_id   = account.id
        account_name = account.name
        region       = var.aws_prod_region
        region_type  = "prod"
      },
      {
        account_id   = account.id
        account_name = account.name
        region       = var.aws_dr_region
        region_type  = "dr"
      }
    ]
  ])
}

###############################################################
# Organization Backup Policy
###############################################################

# Enable cross-account backup and monitoring at organization level
resource "aws_backup_global_settings" "organization" {
  global_settings = {
    "isCrossAccountBackupEnabled"     = "true"
    "isCrossAccountMonitoringEnabled" = "true"
  }
}

# Organization backup policy for all accounts
resource "aws_organizations_policy" "backup_policy" {
  name        = "organization-backup-policy"
  description = "Organization-wide backup policy for all accounts"
  type        = "BACKUP_POLICY"

  content = jsonencode({
    plans = {
      "${var.backup_plan_name}" = {
        regions = {
          "@@assign" = [var.aws_prod_region, var.aws_dr_region]
        }
        rules = {
          "hourly_backup_rule" = {
            schedule_expression     = var.hourly_backup_schedule
            start_window_minutes    = var.backup_plan_start_window
            complete_window_minutes = var.backup_plan_completion_window
            target_backup_vault     = "vault_prod_hourly"
            lifecycle = {
              delete_after_days = var.hourly_backup_retention
            }
          }
          "daily_backup_rule" = {
            schedule_expression     = var.daily_backup_schedule
            start_window_minutes    = var.backup_plan_start_window
            complete_window_minutes = var.backup_plan_completion_window
            target_backup_vault     = "vault_prod_daily"
            copy_actions = {
              "disaster_recovery_copy" = {
                destination_backup_vault_arn = "arn:aws:backup:${var.aws_dr_region}:$$account:backup-vault:vault_disaster_recovery"
                lifecycle = {
                  delete_after_days = var.dr_backup_retention
                }
              }
            }
            lifecycle = {
              delete_after_days = var.daily_backup_retention
            }
          }
          "monthly_backup_rule" = {
            schedule_expression     = var.monthly_backup_schedule
            start_window_minutes    = var.backup_plan_start_window
            complete_window_minutes = var.backup_plan_completion_window
            target_backup_vault     = "vault_prod_monthly"
            lifecycle = {
              delete_after_days = var.monthly_backup_retention
            }
          }
        }
        selections = {
          "tags" = {
            "all_resources_with_backup_tag" = {
              iam_role_arn = "arn:aws:iam::$$account:role/aws_backup_role"
              resources    = ["*"]
              not_resources = [
                "arn:aws:ec2:*:*:instance/*",
                "arn:aws:s3:*"
              ]
              conditions = {
                "string_equals" = {
                  "aws:ResourceTag/backup" = ["true"]
                }
              }
            }
            "ec2_resources_with_backup_tag" = {
              iam_role_arn = "arn:aws:iam::$$account:role/aws_backup_role"
              resources    = ["arn:aws:ec2:*:*:instance/*"]
              conditions = {
                "string_equals" = {
                  "aws:ResourceTag/backup" = ["true"]
                }
              }
            }
          }
        }
        advanced_backup_settings = {
          "ec2" = {
            resource_type = "EC2"
            backup_options = {
              "WindowsVSS" = "enabled"
            }
          }
        }
      }
    }
  })

  tags = var.tags
}

# Attach backup policy to organization root
resource "aws_organizations_policy_attachment" "backup_policy" {
  policy_id = aws_organizations_policy.backup_policy.id
  target_id = data.aws_organizations_organization.current.roots[0].id
}

###############################################################
# Cross-Account Role for Backup Vault Management
###############################################################

# IAM role for cross-account vault deployment
resource "aws_iam_role" "cross_account_backup_deployment" {
  name = "CrossAccountBackupDeploymentRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
      }
    ]
  })

  tags = var.tags
}

# Policy for cross-account backup vault management
resource "aws_iam_role_policy" "cross_account_backup_deployment" {
  name = "CrossAccountBackupDeploymentPolicy"
  role = aws_iam_role.cross_account_backup_deployment.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "backup:CreateBackupVault",
          "backup:DeleteBackupVault",
          "backup:DescribeBackupVault",
          "backup:PutBackupVaultAccessPolicy",
          "backup:DeleteBackupVaultAccessPolicy",
          "backup:PutBackupVaultLockConfiguration",
          "backup:GetBackupVaultAccessPolicy",
          "backup:ListBackupVaults",
          "kms:CreateKey",
          "kms:CreateAlias",
          "kms:DescribeKey",
          "kms:GetKeyPolicy",
          "kms:PutKeyPolicy",
          "kms:EnableKeyRotation",
          "kms:ListAliases",
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PassRole",
          "iam:GetRole",
          "iam:ListRoles"
        ]
        Resource = "*"
      }
    ]
  })
}

###############################################################
# Lambda Function for Cross-Account Vault Deployment
###############################################################

# Lambda execution role
resource "aws_iam_role" "vault_deployment_lambda" {
  name = "VaultDeploymentLambdaRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Lambda policy for cross-account operations
resource "aws_iam_role_policy" "vault_deployment_lambda" {
  name = "VaultDeploymentLambdaPolicy"
  role = aws_iam_role.vault_deployment_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "sts:AssumeRole"
        ]
        Resource = [
          "arn:aws:iam::*:role/OrganizationAccountAccessRole",
          "arn:aws:iam::*:role/AWSControlTowerExecution",
          "arn:aws:iam::*:role/BackupAdministratorRole"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "organizations:ListAccounts",
          "organizations:DescribeAccount"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach AWS Backup Organization Admin Access policy
resource "aws_iam_role_policy_attachment" "backup_org_admin" {
  role       = aws_iam_role.vault_deployment_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupOrganizationAdminAccess"
}

# Lambda function for vault deployment
resource "aws_lambda_function" "vault_deployment" {
  filename         = "${path.module}/lambda/vault_deployment.zip"
  function_name    = "deploy-backup-vaults"
  role             = aws_iam_role.vault_deployment_lambda.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/vault_deployment.zip")
  runtime          = "python3.9"
  timeout          = 300

  environment {
    variables = {
      PROD_REGION         = var.aws_prod_region
      DR_REGION           = var.aws_dr_region
      KMS_KEY_DESCRIPTION = var.key_description
      VAULT_LOCK_DAYS     = var.changeable_for_days
    }
  }

  tags = var.tags
}

# Lambda deployment package (pre-packaged ZIP file)

# EventBridge rule to trigger vault deployment on organization changes
resource "aws_cloudwatch_event_rule" "organization_changes" {
  name        = "organization-account-changes"
  description = "Trigger vault deployment when organization accounts change"

  event_pattern = jsonencode({
    source      = ["aws.organizations"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventSource = ["organizations.amazonaws.com"]
      eventName   = ["CreateAccount", "InviteAccountToOrganization", "AcceptHandshake"]
    }
  })

  tags = var.tags
}

# EventBridge target for Lambda
resource "aws_cloudwatch_event_target" "vault_deployment" {
  rule      = aws_cloudwatch_event_rule.organization_changes.name
  target_id = "VaultDeploymentTarget"
  arn       = aws_lambda_function.vault_deployment.arn
}

# Lambda permission for EventBridge
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.vault_deployment.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.organization_changes.arn
}

# Initial deployment trigger
resource "aws_lambda_invocation" "deploy_vaults" {
  function_name = aws_lambda_function.vault_deployment.function_name

  input = jsonencode({
    accounts = [for account in local.active_accounts : {
      id   = account.id
      name = account.name
    }]
    vault_config = {
      prod_region             = var.aws_prod_region
      dr_region               = var.aws_dr_region
      key_description         = var.key_description
      changeable_for_days     = var.changeable_for_days
      delegated_admin_account = data.aws_caller_identity.current.account_id
      cross_account_role      = var.cross_account_role_name
      tags                    = var.tags
      vault_names = {
        hourly  = var.vault_prod_hourly_name
        daily   = var.vault_prod_daily_name
        monthly = var.vault_prod_monthly_name
        dr      = var.vault_disaster_recovery_name
      }
    }
  })

  depends_on = [
    aws_organizations_policy_attachment.backup_policy
  ]
}

###############################################################
# Monitoring and Notifications
###############################################################

# SNS topic for backup notifications
resource "aws_sns_topic" "backup_notifications" {
  name = "backup-notifications"
  tags = var.tags
}

# CloudWatch alarm for failed backups
resource "aws_cloudwatch_metric_alarm" "backup_failures" {
  alarm_name          = "backup-job-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "NumberOfBackupJobsFailed"
  namespace           = "AWS/Backup"
  period              = "3600"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "This metric monitors backup job failures"
  alarm_actions       = [aws_sns_topic.backup_notifications.arn]

  tags = var.tags
}