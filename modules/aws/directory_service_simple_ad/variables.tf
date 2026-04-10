variable "alias" {
  type        = string
  description = "(Optional) The alias for the directory (must be unique amongst all aliases in AWS). Required for enable_sso."
  default     = null
}

variable "description" {
  type        = string
  description = "(Optional) A textual description for the directory."
  default     = null
}

variable "name" {
  type        = string
  description = "(Required) The fully qualified name for the directory, such as corp.example.com"
}

variable "password" {
  type        = string
  description = "(Required) The password for the directory administrator or connector user."
  sensitive   = true
}

variable "enable_sso" {
  type        = bool
  description = "(Optional) Whether to enable single-sign on for the directory. Requires alias. Defaults to false."
  default     = false
}

variable "short_name" {
  type        = string
  description = "(Optional) The short name of the directory, such as CORP."
  default     = null
}

variable "size" {
  type        = string
  description = "(Required) The size of the directory. Valid values: Small, Large."
  default     = "Small"

  validation {
    condition     = contains(["Small", "Large"], var.size)
    error_message = "Size must be 'Small' or 'Large'."
  }
}

variable "tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = {}
}

variable "type" {
  type        = string
  description = "(Optional) The directory type. For this module, SimpleAD is the supported type."
  default     = "SimpleAD"

  validation {
    condition     = contains(["SimpleAD", "ADConnector", "MicrosoftAD"], var.type)
    error_message = "Type must be one of: SimpleAD, ADConnector, MicrosoftAD."
  }
}

variable "subnet_ids" {
  type        = list(string)
  description = "(Required) The identifiers of the subnets for the directory servers (2 subnets in 2 different AZs)."
  default     = []
}

variable "vpc_id" {
  type        = string
  description = "(Required) The identifier of the VPC that the directory is in."
}
