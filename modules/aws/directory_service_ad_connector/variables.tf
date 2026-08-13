variable "alias" {
  type        = string
  description = "(Optional) The alias for the directory (must be unique amongst all aliases in AWS). Required for enable_sso."
  default     = "default_value"
}

variable "description" {
  type        = string
  description = "(Optional) A textual description for the directory."
  default     = "default_value"
}

variable "name" {
  type        = string
  description = "(Required) The fully qualified name for the directory, such as corp.example.com"
}

variable "password" {
  type        = string
  description = "(Required) The password for the connector user. Changes to this value are ignored -- see the lifecycle block in main.tf. AWS has no API for updating a directory password, so rotate it in Active Directory and in the Directory Service console, then leave this input at its original value."
  sensitive   = true
}

variable "size" {
  type        = string
  description = "(Required for SimpleAD and ADConnector) The size of the directory (Small or Large are accepted values)."
  default     = "Small"
}

variable "tags" {
  type        = map(any)
  description = "(Optional) A mapping of tags to assign to the resource."
  default     = {}
}

variable "type" {
  type        = string
  description = "(Optional) - The directory type (SimpleAD, ADConnector or MicrosoftAD are accepted values). Defaults to SimpleAD."
  default     = "ADConnector"
}

variable "customer_dns_ips" {
  type        = list(string)
  description = "(Required) The DNS IP addresses of the domain to connect to."
  default     = []
}

variable "customer_username" {
  type        = string
  description = "(Required) The username corresponding to the password provided."
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
