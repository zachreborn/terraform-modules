##############################
# Role Variables
##############################

variable "assume_role_policy" {
  type        = string
  description = "(Required) The policy that grants an entity permission to assume the role."
}

variable "description" {
  type        = string
  description = "(Optional) The description of the role."
  default     = null
}

variable "force_detach_policies" {
  type        = bool
  description = "(Optional) Specifies to force detaching any policies the role has before destroying it. Defaults to false."
  default     = false
}

variable "max_session_duration" {
  type        = string
  description = "(Optional) The maximum session duration (in seconds) that you want to set for the specified role. If you do not specify a value for this setting, the default maximum of one hour is applied. This setting can have a value from 1 hour to 12 hours."
  default     = 3600
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "The max_session_duration must be between 3600 and 43200 seconds (1 hour to 12 hours)."
  }
}

variable "name_prefix" {
  type        = string
  description = "(Required) The prefix used to generate a unique role name."
}

variable "path" {
  type        = string
  description = "(Optional) The path to the role."
  default     = "/"
}

variable "permissions_boundary" {
  type        = string
  description = "(Optional) The ARN of the policy that is used to set the permissions boundary for the role."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags to assign to the IAM role."
  default = {
    terraform = "true"
  }
}

##############################
# Policy Attachment Variables
##############################

variable "policy_arns" {
  type        = set(string)
  description = "(Required) - A list of ARNs of the policies which you want attached to the role."
}
