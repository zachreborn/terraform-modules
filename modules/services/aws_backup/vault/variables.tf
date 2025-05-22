variable "name" {
  description = "The name of the backup vault."
  type        = string
}

variable "kms_key_arn" {
  description = "The ARN of the KMS key to use for the backup vault."
  type        = string
}

variable "tags" {
  description = "Tags to apply to the backup vault."
  type        = map(string)
}

variable "enable_vault_lock" {
  description = "Whether to enable vault lock configuration."
  type        = bool
  default     = false
}

variable "changeable_for_days" {
  description = "The number of days the vault lock can be changed."
  type        = number
  default     = 3
}

