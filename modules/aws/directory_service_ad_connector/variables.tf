variable "alias" {
  type        = string
  description = "(Optional) The alias for the directory. Required for enable_sso. WARNING: an alias must be unique across every directory alias in the Region and is immutable -- it is ForceNew, so changing it replaces the directory and destroys anything registered against it. The default below is the shared literal \"default_value\", which means only ONE directory per Region can use the default: a second caller that leaves it unset will fail to create. Set an explicit, meaningful alias, or pass null to let AWS use the directory ID as the alias. The default is retained for backwards compatibility -- changing it is deferred to avoid surprising existing callers."
  default     = "default_value"
}

variable "description" {
  type        = string
  description = "(Optional) A textual description for the directory. WARNING: this is ForceNew -- changing it on an existing directory replaces it and destroys anything registered against it. Treat it as set-once at creation. Note the default is the literal \"default_value\"; it is retained for backwards compatibility because flipping it to null would itself force replacement for existing callers who relied on the default."
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
