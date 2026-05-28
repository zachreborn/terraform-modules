###########################
# Resource Data Sync Variables
###########################

variable "name" {
  description = "(Required) The name of the resource data sync configuration. Must be unique per account and region."
  type        = string
}

variable "create_bucket" {
  description = "(Optional) Whether to create an S3 bucket as the sync destination. Set to true for the central/management account. Set to false for member accounts that target a centrally-created bucket."
  type        = bool
  default     = false
}

variable "bucket_name" {
  description = "(Optional) Name of an existing S3 bucket to use as the sync destination. Required when create_bucket = false. Auto-generated as <name>-ssm-sync-<account_id> when create_bucket = true."
  type        = string
  default     = null
}

variable "bucket_region" {
  description = "(Optional) AWS region of the destination S3 bucket. Required when create_bucket = false. Auto-detected from the current region when create_bucket = true."
  type        = string
  default     = null
}

variable "prefix" {
  description = "(Optional) The S3 key prefix (folder) under which SSM sync data is written. Used in the bucket policy path pattern so all accounts write to a common prefix."
  type        = string
  default     = "ssm-data"
}

variable "kms_key_arn" {
  description = "(Optional) ARN of a KMS key for server-side encryption of the S3 bucket and sync data. If null, AES-256 (SSE-S3) is used."
  type        = string
  default     = null
}

variable "sync_format" {
  description = "(Optional) The format for synced data. JsonSerDe is compatible with Athena and Glue; OrcSerde offers better compression for large inventories."
  type        = string
  default     = "JsonSerDe"
  validation {
    condition     = contains(["JsonSerDe", "OrcSerde"], var.sync_format)
    error_message = "sync_format must be either JsonSerDe or OrcSerde."
  }
}

variable "org_id" {
  description = "(Optional) The AWS Organizations organization ID (e.g. o-xxxxxxxxxx). When provided, the S3 bucket policy restricts SSM writes to sources within this org. Only relevant when create_bucket = true."
  type        = string
  default     = null
}

variable "retention_days" {
  description = "(Optional) Number of days to retain SSM sync data in S3 before expiration. Applies only when create_bucket = true."
  type        = number
  default     = 365
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to created resources."
  type        = map(any)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}
