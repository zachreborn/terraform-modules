###########################
# Placement Variables
###########################

variable "central_account_id" {
  type        = string
  description = "(Required) The AWS account ID of the central backup (delegated administrator) account that holds the compliance-locked central vaults and their CMKs. The backup role's inline policy is scoped to this account's vault and key ARNs so recovery points can be copied cross-account. This is the only value that varies between member accounts (and it is constant org-wide)."
  validation {
    condition     = can(regex("^[0-9]{12}$", var.central_account_id))
    error_message = "central_account_id must be a 12-digit AWS account ID."
  }
}

###########################
# Staging Vault Variables
###########################

variable "staging_vault_name" {
  type        = string
  description = "(Optional) Name of the local, tier-agnostic staging vault. AWS Backup always writes recovery points locally first; this vault must match the staging_vault_name configured in the org BACKUP_POLICY. It is disposable (short retention, no lock)."
  default     = "backup-staging"
}

variable "staging_kms_key_arn" {
  type        = string
  description = "(Optional) ARN of a customer-managed KMS key to encrypt the staging vault. Defaults to null, which uses the AWS-managed AWS Backup key (aws/backup). Cross-account copies of resource types not fully managed by AWS Backup (such as EBS, EC2, and RDS) require customer-managed keys, so set this when those resources are restored by copying back from the central account."
  default     = null
}

variable "staging_vault_force_destroy" {
  type        = bool
  description = "(Optional) Allow Terraform to delete the staging vault even if it contains recovery points. Staging is disposable, but this defaults to false to avoid accidental destruction of in-flight recovery points."
  default     = false
}

variable "staging_retention_days" {
  type        = number
  description = "(Optional) Vault Lock minimum retention for the staging vault, in days. Must equal staging_retention_days in the aws_backup_organization_tiered module, which sets how long every rule keeps its local recovery points; a shorter rule lifecycle fails the lock check. Copy-backs into this vault must also be kept at least this long."
  default     = 10
  validation {
    condition     = var.staging_retention_days >= 1
    error_message = "staging_retention_days must be at least 1."
  }
}

variable "staging_max_retention_days" {
  type        = number
  description = "(Optional) Vault Lock maximum retention for the staging vault, in days. Null sets no maximum."
  default     = null
}

variable "vault_lock_mode" {
  type        = string
  description = "(Optional) AWS Backup Vault Lock mode for the staging vault. \"none\" applies no lock. \"governance\" enforces retention, but principals with the required IAM permissions can remove or alter it. \"compliance\" becomes IRREVERSIBLE (even for root) once the changeable_for_days grace window expires; after that the staging vault can't be deleted while it holds recovery points and its retention floor can't change."
  default     = "none"
  validation {
    condition     = contains(["none", "governance", "compliance"], var.vault_lock_mode)
    error_message = "vault_lock_mode must be one of: none, governance, compliance."
  }
}

variable "changeable_for_days" {
  type        = number
  description = "(Optional) Grace window in days during which a compliance-mode lock can still be removed. AWS minimum is 3. Only applies when vault_lock_mode = \"compliance\"."
  default     = 3
  validation {
    condition     = var.changeable_for_days >= 3
    error_message = "changeable_for_days must be at least 3 (AWS Backup Vault Lock minimum)."
  }
}

###########################
# Backup Role Variables
###########################

variable "backup_role_name" {
  type        = string
  description = "(Optional) Name of the IAM role AWS Backup assumes in this account. Must match the backup_role_name referenced by the org BACKUP_POLICY selections ($account token)."
  default     = "AWSBackupServiceRole"
}

variable "backup_role_path" {
  type        = string
  description = "(Optional) Path for the backup IAM role."
  default     = "/"
}

variable "backup_role_permissions_boundary" {
  type        = string
  description = "(Optional) ARN of a permissions boundary policy to attach to the backup role."
  default     = null
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "(Optional) AWS managed policy ARNs attached to the backup role. Defaults to the AWS Backup service-role policies for backup, restore, and S3 backup/restore, which together cover all AWS Backup-supported resource types."
  default = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Backup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForS3Restore",
  ]
}

###########################
# General Variables
###########################

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to all resources created by this module."
  default     = {}
}
