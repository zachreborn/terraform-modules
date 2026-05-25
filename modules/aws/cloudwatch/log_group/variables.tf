###########################
# Resource Variables
###########################

###########################
# General Variables
###########################

variable "kms_key_id" {
  description = "(Optional) The ARN of the KMS key to use for encryption"
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

variable "name" {
  description = "(Optional) The name of the log group. Conflicts with `name_prefix`. Exactly one of `name` or `name_prefix` must be specified."
  type        = string
  default     = null
}

variable "name_prefix" {
  description = "(Optional) Creates a unique name beginning with the specified prefix. Conflicts with `name`. Exactly one of `name` or `name_prefix` must be specified."
  type        = string
  default     = null
}

variable "retention_in_days" {
  description = "(Optional) Specifies the number of days you want to retain log events in the specified log group. Valid values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, and 3653. Defaults to 90."
  type        = number
  default     = 90
  validation {
    condition     = contains([0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, 3653], var.retention_in_days)
    error_message = "retention_in_days must be one of the valid CloudWatch log retention periods: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, 2192, 2557, 2922, 3288, 3653."
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