variable "name" {
  type        = string
  description = "(Required) Name of the project."
}

variable "organization" {
  type        = string
  description = "(Optional) Name of the organization. If omitted, organization must be defined in the provider config."
  default     = null
}
