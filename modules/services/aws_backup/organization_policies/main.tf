terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = ">= 4.0.0"
      configuration_aliases = [aws.prod_region, aws.dr_region]
    }
  }
}

###############################################################
# IAM
###############################################################
# Assume Role
resource "aws_iam_role" "backup" {
  provider           = aws.prod_region
  name               = "aws_backup_role"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": ["sts:AssumeRole"],
      "Effect": "allow",
      "Principal": {
        "Service": ["backup.amazonaws.com"]
      }
    }
  ]
}
POLICY
}

# Policy Attachment
resource "aws_iam_role_policy_attachment" "backup" {
  provider   = aws.prod_region
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup.name
}

resource "aws_iam_role_policy_attachment" "restores" {
  provider   = aws.prod_region
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores"
  role       = aws_iam_role.backup.name
}

###############################################################
# Backup Plans
###############################################################


#######################################
# AWS Backup Organization Plan
#######################################

module "organization_backup_plan" {
  source = "../../aws/organizations/delegated_resource_policy"

  for_each = var.enable_organization_backup ? [true] : []

  content = file("org_backup_plan.json")
  tags    = var.tags
}

#######################################
# Primary Backup
#######################################
# The following plan and selection are for all services except EC2 instances or AMI
resource "aws_backup_plan" "plan" {
  provider = aws.prod_region
  name     = var.backup_plan_name
  tags     = var.tags

  rule {
    rule_name                = "hourly_backup_rule"
    target_vault_name        = aws_backup_vault.vault_prod_hourly.name
    schedule                 = var.hourly_backup_schedule
    enable_continuous_backup = false
    start_window             = var.backup_plan_start_window
    completion_window        = var.backup_plan_completion_window
    lifecycle {
      delete_after = var.hourly_backup_retention
    }
  }

  rule {
    rule_name                = "daily_backup_rule"
    target_vault_name        = aws_backup_vault.vault_prod_daily.name
    schedule                 = var.daily_backup_schedule
    enable_continuous_backup = false
    start_window             = var.backup_plan_start_window
    completion_window        = var.backup_plan_completion_window
    copy_action {
      destination_vault_arn = aws_backup_vault.vault_disaster_recovery.arn
      lifecycle {
        delete_after = var.dr_backup_retention
      }
    }
    lifecycle {
      delete_after = var.daily_backup_retention
    }
  }

  rule {
    rule_name                = "monthly_backup_rule"
    target_vault_name        = aws_backup_vault.vault_prod_monthly.name
    schedule                 = var.monthly_backup_schedule
    enable_continuous_backup = false
    start_window             = var.backup_plan_start_window
    completion_window        = var.backup_plan_completion_window
    lifecycle {
      # cold_storage_after = "90"
      delete_after = var.monthly_backup_retention
    }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }
}

#######################################
# Backup Selection
#######################################

resource "aws_backup_selection" "all_resources" {
  provider     = aws.prod_region
  iam_role_arn = aws_iam_role.backup.arn
  name         = "all_except_ec2_and_s3"
  plan_id      = aws_backup_plan.plan.id
  resources = [
    "*"
  ]
  not_resources = [
    "arn:aws:ec2:*:*:instance/*",
    "arn:aws:s3:*"
  ]
}

#######################################
# EC2 AMI Backup
#######################################
# The following plan and selection are for EC2 resources
resource "aws_backup_plan" "ec2_plan" {
  provider = aws.prod_region
  name     = var.ec2_backup_plan_name
  tags     = var.tags

  rule {
    rule_name                = "daily_backup_rule"
    target_vault_name        = aws_backup_vault.vault_prod_daily.name
    schedule                 = "cron(20 9 * * ? *)"
    enable_continuous_backup = false
    start_window             = var.backup_plan_start_window
    completion_window        = var.backup_plan_completion_window
    copy_action {
      destination_vault_arn = aws_backup_vault.vault_disaster_recovery.arn
      lifecycle {
        delete_after = var.dr_backup_retention
      }
    }
    lifecycle {
      delete_after = var.daily_backup_retention
    }
  }

  advanced_backup_setting {
    backup_options = {
      WindowsVSS = "enabled"
    }
    resource_type = "EC2"
  }
}

#######################################
# Backup Selection
#######################################

resource "aws_backup_selection" "all_ec2" {
  provider     = aws.prod_region
  iam_role_arn = aws_iam_role.backup.arn
  name         = "all_ec2"
  plan_id      = aws_backup_plan.ec2_plan.id
  resources = [
    "arn:aws:ec2:*:*:instance/*"
  ]
}

###############################################################
# Backup Notifications
###############################################################
# To be added
