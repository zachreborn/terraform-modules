###########################
# Managed Prefix List Variables
###########################

variable "address_family" {
  description = "(Optional) Address family (IPv4 or IPv6) of this prefix list. Changing this forces a new resource to be created."
  type        = string
  default     = "IPv4"
  validation {
    condition     = contains(["IPv4", "IPv6"], var.address_family)
    error_message = "address_family must be either 'IPv4' or 'IPv6'."
  }
}

variable "entries" {
  description = "(Optional) List of CIDR entry objects to add to the prefix list. Each object requires a 'cidr' key and accepts an optional 'description' key."
  type = list(object({
    cidr        = string
    description = optional(string)
  }))
  default = []
}

variable "max_entries" {
  description = "(Optional) Maximum number of entries that this prefix list can contain."
  type        = number
  default     = 10
  validation {
    condition     = var.max_entries >= 1
    error_message = "max_entries must be at least 1."
  }
}

variable "name" {
  description = "(Required) Name of this prefix list. The name must not start with 'com.amazonaws'."
  type        = string
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to this resource."
  type        = map(any)
  default = {
    created_by  = "terraform"
    terraform   = "true"
    environment = "prod"
  }
}
