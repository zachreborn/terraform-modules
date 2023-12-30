variable "description" {
  description = "(Optional) The description of the permission set."
  type        = string
  default     = null
}

variable "name" {
  description = "(Required) The name of the permission set."
  type        = string
}

variable "relay_state" {
  description = "(Optional) The relay state URL used to redirect users within the application during the federation authentication process."
  type        = string
  default     = null
}

variable "session_duration" {
  description = "(Optional) The length of time that the application user sessions are valid in the ISO-8601 standard."
  type        = string
  default     = "PT1H"
}

variable "tags" {
  description = "(Optional) Key-value map of resource tags."
  type        = map(string)
  default     = {}
}
