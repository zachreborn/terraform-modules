###########################
# Resource Variables
###########################
variable "name" {
  description = "Name of the instance profile, unique within the account regardless of path or role. Forces replacement. Exactly one of name or name_prefix is required."
  type        = string
  default     = null

  validation {
    condition     = var.name == null ? true : can(regex("^[\\w+=,.@-]{1,128}$", var.name))
    error_message = "name must contain 1-128 letters, digits, or the characters _+=,.@-."
  }
}

variable "name_prefix" {
  description = "Prefix for a generated unique instance-profile name. Forces replacement. Exactly one of name or name_prefix is required."
  type        = string
  default     = null

  validation {
    condition     = var.name_prefix == null ? true : can(regex("^[\\w+=,.@-]{1,102}$", var.name_prefix))
    error_message = "name_prefix must contain 1-102 letters, digits, or the characters _+=,.@-."
  }
}

variable "path" {
  description = "Path to the instance profile, beginning and ending with / and at most 512 characters. Forces replacement."
  type        = string
  default     = "/"
  nullable    = false

  validation {
    condition     = can(regex("^/", var.path)) && can(regex("/$", var.path)) && length(var.path) <= 512
    error_message = "path must begin and end with / and contain at most 512 characters."
  }
}

variable "role" {
  description = "Name (not ARN or path) of an existing IAM role to attach. The role must trust EC2 or the relevant service; this module does not create or verify it."
  type        = string
  nullable    = false

  validation {
    condition     = var.role != ""
    error_message = "role must not be empty."
  }

  validation {
    # startswith() requires Terraform 1.3; regex preserves the module's 1.2 floor.
    condition     = !can(regex("^arn:", var.role))
    error_message = "role requires the IAM role name, not an ARN. Use module.my_role.name or supply the last path segment of the ARN."
  }

  validation {
    condition     = can(regex("^[\\w+=,.@-]{1,64}$", var.role))
    error_message = "role must be an IAM role name of 1-64 letters, digits, or the characters _+=,.@-; paths are not allowed."
  }
}

###########################
# General Variables
###########################
variable "tags" {
  description = "Tags for the instance profile. A supplied map replaces the default; Name is merged when name is set, and caller tags take precedence."
  type        = map(string)
  default = {
    terraform = "true"
  }
  nullable = false
}
