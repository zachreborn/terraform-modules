###############################################################
# General Variables
###############################################################

variable "aws_prod_region" {
  type        = string
  description = "AWS production region where primary backup vaults will be created"
  default     = "us-west-2"
}

variable "aws_dr_region" {
  type        = string
  description = "AWS disaster recovery region where DR backup vaults will be created"
  default     = "us-east-2"
}

variable "tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to all resources"
  default = {
    aws_backup  = "true"
    created_by  = "terraform"
    environment = "prod"
    priority    = "critical"
    service     = "backups"
    terraform   = "true"
  }
}

###############################################################
# Backup Plan Variables
###############################################################

variable "backup_plan_name" {
  type        = string
  description = "(Required) The display name of the organization backup plan"
  default     = "organization_backup_plan"
}

variable "backup_plan_start_window" {
  type        = number
  description = "(Optional) The amount of time in minutes before beginning a backup"
  default     = 60
}

variable "backup_plan_completion_window" {
  type        = number
  description = "(Optional) The amount of time in minutes AWS Backup attempts a backup before canceling the job and returning an error"
  default     = 1440
}

###############################################################
# Backup Schedule Variables
###############################################################

variable "hourly_backup_schedule" {
  type        = string
  description = "(Required) The hourly backup plan schedule in cron format"
  default     = "cron(20 * * * ? *)"
}

variable "daily_backup_schedule" {
  type        = string
  description = "(Required) The daily backup plan schedule in cron format"
  default     = "cron(20 7 * * ? *)"
}

variable "monthly_backup_schedule" {
  type        = string
  description = "(Required) The monthly backup plan schedule in cron format"
  default     = "cron(20 9 1 * ? *)"
}

###############################################################
# Backup Retention Variables
###############################################################

variable "hourly_backup_retention" {
  type        = number
  description = "(Required) The hourly backup plan retention in days"
  default     = 3
}

variable "daily_backup_retention" {
  type        = number
  description = "(Required) The daily backup plan retention in days"
  default     = 30
}

variable "monthly_backup_retention" {
  type        = number
  description = "(Required) The monthly backup plan retention in days"
  default     = 365
}

variable "dr_backup_retention" {
  type        = number
  description = "(Required) The disaster recovery backup plan retention in days"
  default     = 7
}

###############################################################
# Vault Variables
###############################################################

variable "vault_prod_hourly_name" {
  type        = string
  description = "Name for production hourly backup vault"
  default     = "vault_prod_hourly"
}

variable "vault_prod_daily_name" {
  type        = string
  description = "Name for production daily backup vault"
  default     = "vault_prod_daily"
}

variable "vault_prod_monthly_name" {
  type        = string
  description = "Name for production monthly backup vault"
  default     = "vault_prod_monthly"
}

variable "vault_disaster_recovery_name" {
  type        = string
  description = "Name for disaster recovery backup vault"
  default     = "vault_disaster_recovery"
}

variable "changeable_for_days" {
  type        = number
  description = "(Optional) The number of days after which the vault lock configuration is no longer changeable"
  default     = 3
}

###############################################################
# KMS Variables
###############################################################

variable "key_description" {
  type        = string
  description = "(Optional) The description of the KMS key as viewed in AWS console"
  default     = "AWS backups kms key used to encrypt backups"
}

variable "key_deletion_window_in_days" {
  type        = number
  description = "(Optional) Duration in days after which the key is deleted after destruction of the resource"
  default     = 30
}

variable "key_enable_key_rotation" {
  type        = bool
  description = "(Optional) Specifies whether key rotation is enabled"
  default     = true
}

###############################################################
# Organization Variables
###############################################################

variable "excluded_account_ids" {
  type        = list(string)
  description = "(Optional) List of account IDs to exclude from backup policy deployment"
  default     = []
}

variable "target_organizational_units" {
  type        = list(string)
  description = "(Optional) List of organizational unit IDs to target for backup policy. If empty, applies to root"
  default     = []
}

variable "backup_tag_key" {
  type        = string
  description = "(Optional) Tag key used to identify resources for backup"
  default     = "backup"
}

variable "backup_tag_value" {
  type        = string
  description = "(Optional) Tag value used to identify resources for backup"
  default     = "true"
}

###############################################################
# Cross-Account Role Variables
###############################################################

variable "cross_account_role_name" {
  type        = string
  description = "(Optional) Name of the cross-account role for backup vault deployment"
  default     = "OrganizationAccountAccessRole"
}

###############################################################
# Notification Variables
###############################################################

variable "enable_backup_notifications" {
  type        = bool
  description = "(Optional) Enable SNS notifications for backup job status"
  default     = true
}

variable "notification_email" {
  type        = string
  description = "(Optional) Email address for backup notifications"
  default     = ""
}