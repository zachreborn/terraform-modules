############################
# Azure AD Group Variables
############################

variable "auto_subscribe_new_members" {
  type        = bool
  description = "(Optional) Indicates whether new members added to the group will be auto-subscribed to receive email notifications. Can only be set for Unified groups."
  default     = null
  validation {
    condition     = var.auto_subscribe_new_members == null ? true : can(regex("true|false", var.auto_subscribe_new_members))
    error_message = "The value of auto_subscribe_new_members must be true, false or null."
  }
}

variable "description" {
  type        = string
  description = "(Optional) A description for the group."
  default     = null
}

variable "display_name" {
  type        = string
  description = "(Required) The display name for the group."
}

variable "external_senders_allowed" {
  type        = bool
  description = "(Optional) Indicates whether external senders can send messages to the group. Can only be set for Unified groups."
  default     = null
  validation {
    condition     = var.external_senders_allowed == null ? true : can(regex("true|false", var.external_senders_allowed))
    error_message = "The value of external_senders_allowed must be true, false or null."
  }
}

variable "hide_from_address_lists" {
  type        = bool
  description = "(Optional) Indicates whether the group is displayed in certain parts of the Outlook user interface: in the Address Book, in address lists for selecting message recipients, and in the Browse Groups dialog for searching groups. Can only be set for Unified groups."
  default     = null
  validation {
    condition     = var.hide_from_address_lists == null ? true : can(regex("true|false", var.hide_from_address_lists))
    error_message = "The value of hide_from_address_lists must be true, false or null."
  }
}

variable "hide_from_outlook_clients" {
  type        = bool
  description = "(Optional) Indicates whether the group is displayed in Outlook clients, such as Outlook for Windows and Outlook on the web. Can only be set for Unified groups."
  default     = null
  validation {
    condition     = var.hide_from_outlook_clients == null ? true : can(regex("true|false", var.hide_from_outlook_clients))
    error_message = "The value of hide_from_outlook_clients must be true, false or null."
  }
}

variable "mail_enabled" {
  type        = bool
  description = "(Optional) Whether the group is a mail enabled, with a shared group mailbox. At least one of mail_enabled or security_enabled must be specified. Only Microsoft 365 groups can be mail enabled (see the types property)."
  default     = null
  validation {
    condition     = var.mail_enabled == null ? true : can(regex("true|false", var.mail_enabled))
    error_message = "The value of mail_enabled must be true, false or null."
  }
}

variable "mail_nickname" {
  type        = string
  description = "(Optional) The mail alias for the group, unique in the organisation. Required for mail-enabled groups. Changing this forces a new resource to be created."
  default     = null
}

variable "members" {
  type        = list(string)
  description = "(Optional) A list of members who should be present in this group. Supported object types are Users, Groups or Service Principals. Cannot be used with the dynamic_membership block."
  default     = null
}

variable "owners" {
  type        = list(string)
  description = "(Optional) A set of object IDs of principals that will be granted ownership of the group. Supported object types are users or service principals. By default, the principal being used to execute Terraform is assigned as the sole owner. Groups cannot be created with no owners or have all their owners removed."
  default     = null
}

variable "prevent_duplicate_names" {
  type        = bool
  description = "(Optional) If true, will return an error if an existing group is found with the same name. Defaults to false."
  default     = null
  validation {
    condition     = var.prevent_duplicate_names == null ? true : can(regex("true|false", var.prevent_duplicate_names))
    error_message = "The value of prevent_duplicate_names must be true, false or null."
  }
}

variable "provisioning_options" {
  type        = list(string)
  description = "(Optional) A list of provisioning options for a Microsoft 365 group. The only supported value is Team. See official documentation for details. Changing this forces a new resource to be created."
  default     = null
}

variable "security_enabled" {
  type        = bool
  description = "(Optional) Whether the group is a security group for controlling access to in-app resources. At least one of security_enabled or mail_enabled must be specified. A Microsoft 365 group can be security enabled and mail enabled (see the types property)."
  default     = null
  validation {
    condition     = var.security_enabled == null ? true : can(regex("true|false", var.security_enabled))
    error_message = "The value of security_enabled must be true, false or null."
  }
}

variable "types" {
  type        = list(string)
  description = "(Optional) A list of group types to configure for the group. Supported values are DynamicMembership, which denotes a group with dynamic membership, and Unified, which specifies a Microsoft 365 group. Required when mail_enabled is true. Changing this forces a new resource to be created."
  default     = null
}

variable "visibility" {
  type        = string
  description = "(Optional) The group join policy and group content visibility. Possible values are Private, Public, or Hiddenmembership. Only Microsoft 365 groups can have Hiddenmembership visibility and this value must be set when the group is created. By default, security groups will receive Private visibility and Microsoft 365 groups will receive Public visibility."
  default     = null
  validation {
    condition     = var.visibility == null ? true : can(regex("Private|Public|Hiddenmembership", var.visibility))
    error_message = "The value of visibility must be Private, Public, Hiddenmembership or null."
  }
}

variable "dynamic_membership" {
  type = object({
    enabled = bool
    rule    = string
  })
  description = "(Optional) A dynamic membership block. Cannot be used with the members property."
  default     = null
}
