variable "assume_role_policy" {
  type        = string
  description = "(Required) The policy that grants an entity permission to assume the role."
}

variable "description" {
  type        = string
  description = "(Optional) The description of the role."
  default     = ""
}

variable "force_detach_policies" {
  type        = bool
  description = "(Optional) Specifies to force detaching any policies the role has before destroying it. Defaults to false."
  default     = false

  validation {
    condition     = var.force_detach_policies == false || var.force_detach_policies == true
    error_message = "force_detach_policies must be either true or false"
  }
}

variable "max_session_duration" {
  type        = string
  description = "(Optional) The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
  default     = 3600
}

variable "name" {
  type        = string
  description = "(Required) The friendly IAM role name to match."
}

variable "path" {
  type        = string
  description = "(Optional) The path to the role."
  default     = "/"
}

variable "permissions_boundary" {
  type        = string
  description = "(Optional) The ARN of the policy that is used to set the permissions boundary for the role."
  default     = ""
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the IAM role."
  default = {
    terraform = "true"
  }
}
