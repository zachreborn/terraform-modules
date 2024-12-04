###########################
# Resource Variables
###########################

###########################
# General Variables
###########################

variable "kms_key_id" {
  description = "(Optiona) The ARN of the KMS key to use for encryption"
  type        = string
  default     = null
}

variable "log_group_class" {
  description = "(Optional) The class of the log group. Valid values are 'STANDARD' and 'INFREQUENT_ACCESS'. Defaults to 'STANDARD'."
  type        = string
  default     = "STANDARD"
  validation {
    condition     = var.log_group_class == "STANDARD" || var.log_group_class == "INFREQUENT_ACCESS"
    error_message = "log_group_class must be either 'STANDARD' or 'INFREQUENT_ACCESS'"
  }
}

variable "name_prefix" {
  description = "(Required) The name prefix of the log group"
  type        = string
}

variable "retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Valid values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, and 3653. Defaults to 90."
  type        = number
  default     = 90
  validation {
    condition     = var.retention_in_days >= 0 && var.retention_in_days <= 3653
    error_message = "retention_in_days must be between 0 and 3653"
  }
}

variable "skip_destroy" {
  description = "(Optional) If set to true, the log group will not be destroyed at the end of the lifecycle. Defaults to false."
  type        = bool
  default     = false
}

variable "tags" {
  description = "(Optional) Key-value mapping of resource tags"
  type        = map(string)
  default = {
    terraform = "true"
  }
}