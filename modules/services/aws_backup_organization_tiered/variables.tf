###########################
# Tier Model Variables
###########################

variable "backup_tiers" {
  description = <<-EOT
    (Required) The single source of truth for the tiered backup model. A map keyed by tier
    identifier (the value written to the `backup-tier` tag, e.g. "1".."4" or "xs".."xl"). Each
    tier declares its central copy/DR behavior, the Vault Lock retention floor for its central
    vaults, and an ordered list of backup rules. The module derives the org BACKUP_POLICY and the
    central vault set entirely from this map: add a tier by adding a key, change a dimension by
    editing one place. Tier keys are arbitrary strings and become the `backup-tier` tag value.

    Per-rule fields:
      name                      - rule name (unique within the tier).
      schedule                  - cron() expression. AWS Backup scheduled-snapshot floor is 1 hour.
      continuous                - enable continuous backup / PITR (supported services only). PITR is
                                  local-staging only; copy_actions are not emitted for continuous rules.
      central_copy              - copy the recovery point cross-account into the central vault(s).
      start_window_minutes      - backup start window.
      completion_window_minutes - backup completion window.
      local_delete_after_days   - staging (local) copy lifetime. Staging is disposable; keep short.
      central_delete_after_days - immutable central copy retention.
      central_cold_after_days   - Glacier-class transition for the central copy (null = none). AWS
                                  requires central_delete_after_days >= central_cold_after_days + 90.
  EOT
  type = map(object({
    description              = string
    copy_to_dr               = bool
    vault_min_retention_days = optional(number, 30)
    rules = list(object({
      name                      = string
      schedule                  = string
      continuous                = optional(bool, false)
      central_copy              = optional(bool, true)
      start_window_minutes      = optional(number, 60)
      completion_window_minutes = optional(number, 1440)
      local_delete_after_days   = number
      central_delete_after_days = number
      central_cold_after_days   = optional(number, null)
    }))
  }))

  validation {
    condition = alltrue(flatten([
      for tkey, tier in var.backup_tiers : [
        for rule in tier.rules :
        rule.central_cold_after_days == null ? true : rule.central_delete_after_days >= rule.central_cold_after_days + 90
      ]
    ]))
    error_message = "For every rule with a cold-storage transition, central_delete_after_days must be at least central_cold_after_days + 90 (AWS Backup cold-storage minimum)."
  }

  validation {
    condition = alltrue(flatten([
      for tkey, tier in var.backup_tiers : [
        for rule in tier.rules : tier.vault_min_retention_days <= rule.central_delete_after_days
      ]
    ]))
    error_message = "vault_min_retention_days for each tier must be <= the shortest central_delete_after_days of its rules, so locked vaults never block scheduled expiry."
  }
}

###########################
# Placement & Naming Variables
###########################

variable "central_account_id" {
  type        = string
  description = "(Required) The AWS account ID of the central backup (delegated administrator) account that holds the compliance-locked central vaults. Used as the literal account in copy-destination ARNs and as the KMS key administrator principal."
  validation {
    condition     = can(regex("^[0-9]{12}$", var.central_account_id))
    error_message = "central_account_id must be a 12-digit AWS account ID."
  }
}

variable "prod_region" {
  type        = string
  description = "(Optional) The primary region in which the BACKUP_POLICY plans run in member accounts and in which the always-on central vaults are created."
  default     = "us-west-2"
}

variable "dr_region" {
  type        = string
  description = "(Optional) The disaster-recovery region. Central vaults are created here for tiers with copy_to_dr = true, and rules in those tiers gain a second cross-region copy_action targeting this region."
  default     = "us-east-2"
}

variable "policy_regions" {
  type        = list(string)
  description = "(Optional) The regions the BACKUP_POLICY plans deploy to within each member account. Defaults to the prod_region only; cross-region protection is delivered by the central us-east-2 copy_action, not by running the plan in the DR region."
  default     = null
}

variable "tag_key" {
  type        = string
  description = "(Optional) The resource tag key that steers a resource into a tier. Its value must equal one of the backup_tiers keys."
  default     = "backup-tier"
}

variable "policy_name" {
  type        = string
  description = "(Optional) Name of the AWS Organizations BACKUP_POLICY. Also used as the per-tier plan-name prefix."
  default     = "sunward-tiered-backup"
}

variable "staging_vault_name" {
  type        = string
  description = "(Optional) Name of the tier-agnostic local staging vault that must pre-exist in every member account (created by the aws_backup_member module). Recovery points land here first, then copy_actions ship them to the central vault(s)."
  default     = "backup-staging"
}

variable "backup_role_name" {
  type        = string
  description = "(Optional) Name of the IAM role AWS Backup assumes in each member account. Must match the role created by the aws_backup_member module. Referenced in selections via the $account policy token."
  default     = "SunwardAWSBackupRole"
}

variable "central_vault_prefix" {
  type        = string
  description = "(Optional) Name prefix for the central vaults. The tier key is appended (e.g. central-vault-1). The same vault name is used in both prod_region and dr_region; the region is carried in the ARN."
  default     = "central-vault-"
}

variable "target_ou_ids" {
  type        = list(string)
  description = "(Required) Organizational Unit IDs to attach the BACKUP_POLICY to. Attach to workload OUs, never the org root, so the management account is excluded. New accounts placed in these OUs inherit the policy automatically."
}

###########################
# Vault Lock Variables
###########################

variable "enable_vault_lock" {
  type        = bool
  description = "(Optional) Apply AWS Backup Vault Lock in COMPLIANCE mode to the central vaults. Compliance mode is IRREVERSIBLE once the changeable_for_days grace window expires. Leave false to validate the cross-account copy + KMS wiring against reversible vaults first, then flip to true to commit immutability."
  default     = false
}

variable "changeable_for_days" {
  type        = number
  description = "(Optional) Grace window, in days, during which a COMPLIANCE-mode Vault Lock can still be deleted. After this window the lock is permanent. AWS minimum is 3. Only applies when enable_vault_lock = true."
  default     = 3
  validation {
    condition     = var.changeable_for_days >= 3
    error_message = "changeable_for_days must be at least 3 (AWS Backup Vault Lock minimum)."
  }
}

###########################
# KMS Variables
###########################

variable "kms_deletion_window_in_days" {
  type        = number
  description = "(Optional) Duration in days before a destroyed central KMS key is deleted. Must be between 7 and 30."
  default     = 30
  validation {
    condition     = var.kms_deletion_window_in_days >= 7 && var.kms_deletion_window_in_days <= 30
    error_message = "kms_deletion_window_in_days must be between 7 and 30."
  }
}

variable "kms_enable_key_rotation" {
  type        = bool
  description = "(Optional) Enable automatic annual rotation of the central KMS keys."
  default     = true
}

###########################
# Audit Manager Variables
###########################

variable "enable_audit_manager" {
  type        = bool
  description = "(Optional) Create an AWS Backup Audit Manager framework and report plan in the central account to codify the tier rules and produce org-wide compliance reporting."
  default     = false
}

variable "audit_report_s3_bucket_name" {
  type        = string
  description = "(Optional) Name of an existing S3 bucket to deliver Audit Manager report plan output to. Required when enable_audit_manager = true."
  default     = null
}

###########################
# General Variables
###########################

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to all resources created by this module."
  default = {
    terraform = "true"
    service   = "backups"
  }
}
