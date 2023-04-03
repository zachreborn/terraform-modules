variable "allow_force_delete_workspaces" {
  type        = bool
  description = "(Optional) Whether workspace administrators are permitted to delete workspaces with resources under management. If false, only organization owners may delete these workspaces. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.allow_force_delete_workspaces))
    error_message = "The value of allow_force_delete_workspaces must be either true or false."
  }
}

variable "assessments_enforced" {
  type        = bool
  description = "(Optional) (Available only in Terraform Cloud) Whether to force health assessments (drift detection) on all eligible workspaces or allow workspaces to set thier own preferences. Defaults to false."
  default     = false
  validation {
    condition     = can(regex("true|false", var.assessments_enforced))
    error_message = "The value of assessments_enforced must be either true or false."
  }
}

variable "collaborator_auth_policy" {
  type        = string
  description = "(Optional) Authentication policy (password or two_factor_mandatory). Defaults to two_factor_mandatory."
  default     = "two_factor_mandatory"
  validation {
    condition     = can(regex("password|two_factor_mandatory", var.collaborator_auth_policy))
    error_message = "The value of collaborator_auth_policy must be either password or two_factor_mandatory."
  }
}

variable "cost_estimation_enabled" {
  type        = bool
  description = "(Optional) Whether or not the cost estimation feature is enabled for all workspaces in the organization. Defaults to true. In a Terraform Cloud organization which does not have Teams & Governance features, this value is always false and cannot be changed. In Terraform Enterprise, Cost Estimation must also be enabled in Site Administration."
  default     = false
  validation {
    condition     = can(regex("true|false", var.cost_estimation_enabled))
    error_message = "The value of cost_estimation_enabled must be either true or false."
  }
}

variable "email" {
  type        = string
  description = "(Required) Admin email address."
}

variable "name" {
  type        = string
  description = "(Required) Name of the organization."
}

variable "owners_team_saml_role_id" {
  type        = string
  description = "(Optional) The name of the 'owners' team."
  default     = "owners"
}

variable "session_timeout_minutes" {
  type        = number
  description = "(Optional) Session timeout after inactivity in minutes. Defaults to 720."
  default     = 720
  validation {
    condition     = can(regex("^[0-9]+$", var.session_timeout_minutes))
    error_message = "The value of session_timeout_minutes must be a number."
  }
}

variable "session_remember_minutes" {
  type        = number
  description = "(Optional) Session expiration in minutes. Defaults to 720."
  default     = 720
  validation {
    condition     = can(regex("^[0-9]+$", var.session_remember_minutes))
    error_message = "The value of session_remember_minutes must be a number."
  }
}

variable "send_passing_statuses_for_untriggered_speculative_plans" {
  type        = bool
  description = "(Optional) Whether or not to send VCS status updates for untriggered speculative plans. This can be useful if large numbers of untriggered workspaces are exhausting request limits for connected version control service providers like GitHub. Defaults to false. In Terraform Enterprise, this setting has no effect and cannot be changed but is also available in Site Administration."
  default     = false
  validation {
    condition     = can(regex("true|false", var.send_passing_statuses_for_untriggered_speculative_plans))
    error_message = "The value of send_passing_statuses_for_untriggered_speculative_plans must be either true or false."
  }
}
