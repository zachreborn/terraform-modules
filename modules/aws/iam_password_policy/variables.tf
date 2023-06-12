variable "allow_users_to_change_password" {
  type        = bool
  description = "(Optional) Whether to allow users to change their own password"
  default     = true
  validation {
    condition    = can(regex("^true|false$", var.allow_users_to_change_password))
    error_message = "allow_users_to_change_password must be true or false"
  }
}

variable "hard_expiry" {
  type        = bool
  description = "(Optional) Whether users are prevented from setting a new password after their password has expired (i.e. require administrator reset)"
  default     = false
  validation {
    condition    = can(regex("^true|false$", var.hard_expiry))
    error_message = "hard_expiry must be true or false"
  }
}

variable "max_password_age" {
  type        = number
  description = "(Optional) The number of days that an user password is valid."
  default     = null
  validation {
    condition    = var.max_password_age == null ? true : (var.max_password_age > 0 && var.max_password_age < 1095)
    error_message = "max_password_age must be null, or between 1 and 1095"
  }
}

variable "minimum_password_length" {
  type        = number
  description = "(Optional) Minimum length to require for user passwords. Recommended to be set to >= 14."
  default     = 14
  validation {
    condition    = var.minimum_password_length > 0 && var.minimum_password_length < 128
    error_message = "minimum_password_length must be between 1 and 128"
  }
}

variable "password_reuse_prevention" {
  type        = number
  description = "(Optional) The number of previous passwords that users are prevented from reusing."
  default     = 24
  validation {
    condition    = var.password_reuse_prevention == null ? true : (var.password_reuse_prevention > 0 && var.password_reuse_prevention < 25)
    error_message = "password_reuse_prevention must be null, or between 1 and 24"
  }
}

variable "require_lowercase_characters" {
  type        = bool
  description = "(Optional) Whether to require lowercase characters for user passwords."
  default     = true
  validation {
    condition    = can(regex("^true|false$", var.require_lowercase_characters))
    error_message = "require_lowercase_characters must be true or false"
  }
}

variable "require_numbers" {
  type        = bool
  description = "(Optional) Whether to require numbers for user passwords."
  default     = true
  validation {
    condition    = can(regex("^true|false$", var.require_numbers))
    error_message = "require_numbers must be true or false"
  }
}

variable "require_symbols" {
  type        = bool
  description = "(Optional) Whether to require symbols for user passwords."
  default     = true
  validation {
    condition    = can(regex("^true|false$", var.require_symbols))
    error_message = "require_symbols must be true or false"
  }
}

variable "require_uppercase_characters" {
  type        = bool
  description = "(Optional) Whether to require uppercase characters for user passwords."
  default     = true
  validation {
    condition    = can(regex("^true|false$", var.require_uppercase_characters))
    error_message = "require_uppercase_characters must be true or false"
  }
}
