variable "name" {
  type        = string
  description = "(Optional) Name of the IAM role. Amazon WorkSpaces looks for a role named workspaces_DefaultRole by default, so only change this if you understand the implications documented in the AWS WorkSpaces Administration Guide."
  default     = "workspaces_DefaultRole"
}

variable "enable_self_service_access" {
  type        = bool
  description = "(Optional) If true, additionally attaches the AmazonWorkSpacesSelfServiceAccess managed policy so this role also covers self-service actions (rebuild, restart, change compute type, etc.), in addition to the always-attached AmazonWorkSpacesServiceAccess policy. Defaults to false."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the IAM role."
  default     = {}
}
