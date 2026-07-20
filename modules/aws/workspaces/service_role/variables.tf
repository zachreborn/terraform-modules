variable "name" {
  type        = string
  description = "(Optional) Name of the IAM role. Amazon WorkSpaces looks up this role by the exact, hard-coded name workspaces_DefaultRole -- the WorkSpaces directory/desktop APIs do not accept an alternate role name, so this must always be exactly \"workspaces_DefaultRole\". Exposed as a variable (rather than a hard-coded literal) purely for self-documentation/testability; it is validated below and cannot actually be changed to a working alternate value."
  default     = "workspaces_DefaultRole"

  validation {
    condition     = var.name == "workspaces_DefaultRole"
    error_message = "name must be exactly \"workspaces_DefaultRole\" -- Amazon WorkSpaces discovers this role by that fixed name and does not accept an alternate one."
  }
}

variable "enable_self_service_access" {
  type        = bool
  description = "(Optional) If true (the default), additionally attaches the AmazonWorkSpacesSelfServiceAccess managed policy so this role also covers self-service actions (rebuild, restart, change compute type, etc.), in addition to the always-attached AmazonWorkSpacesServiceAccess policy. Defaults to true to match AWS's own default workspaces_DefaultRole setup (both managed policies attached) and modules/aws/workspaces/directory's own secure-by-default restart_workspace = true -- setting this false would advertise self-service restart without the IAM permission needed to perform it. Set to false only if you intend to also disable every directory self-service permission."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the IAM role."
  default     = {}
}
