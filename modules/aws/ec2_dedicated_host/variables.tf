###########################
# Required Variables
###########################

variable "availability_zone" {
  type        = string
  description = "(Required) The Availability Zone in which to allocate the Dedicated Host."
}

variable "instance_type" {
  type        = string
  description = "(Required) Specifies the instance type to be supported by the Dedicated Hosts. e.g. mac-m4.metal, mac2-m2.metal."
}

variable "name" {
  type        = string
  description = "(Required) The name tag to assign to the Dedicated Host."
}

###########################
# Optional Variables
###########################

variable "auto_placement" {
  type        = string
  description = "(Optional) Indicates whether the host accepts any untargeted instance launches that match its instance type configuration, or if it only accepts Host tenancy instance launches that specify its unique host ID. Valid values: 'on' or 'off'. Default: 'on'."
  default     = "on"

  validation {
    condition     = can(regex("^(on|off)$", var.auto_placement))
    error_message = "The value must be either 'on' or 'off'."
  }
}

variable "host_recovery" {
  type        = string
  description = "(Optional) Indicates whether to enable or disable host recovery for the Dedicated Host. Valid values: 'on' or 'off'. Default: 'off'."
  default     = "off"

  validation {
    condition     = can(regex("^(on|off)$", var.host_recovery))
    error_message = "The value must be either 'on' or 'off'."
  }
}

variable "tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the resource."
  default = {
    terraform = "true"
  }
}
