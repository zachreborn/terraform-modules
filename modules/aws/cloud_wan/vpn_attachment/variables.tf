###########################
# Customer Gateway Configuration
###########################

variable "customer_gateways" {
  type = list(object({
    name            = string
    ip_address      = string
    bgp_asn         = number
    certificate_arn = optional(string)
  }))
  description = "(Required) List of customer gateway configurations."
  validation {
    condition = alltrue([
      for gw in var.customer_gateways :
      can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}$", gw.ip_address))
    ])
    error_message = "All customer gateway IP addresses must be valid IPv4 addresses."
  }
}

###########################
# VPN Connection Configuration
###########################

variable "static_routes_only" {
  type        = bool
  description = "(Optional) Whether the VPN connection uses static routes exclusively. Defaults to true."
  default     = true
}

variable "tunnel_ike_versions" {
  type        = list(string)
  description = "(Optional) The IKE versions that are permitted for the VPN tunnels. Valid values are ikev1 | ikev2."
  default     = ["ikev2"]
  validation {
    condition = alltrue([
      for version in var.tunnel_ike_versions :
      can(index(["ikev1", "ikev2"], version))
    ])
    error_message = "tunnel_ike_versions must contain only ikev1 or ikev2."
  }
}

variable "tunnel_phase1_dh_group_numbers" {
  type        = list(string)
  description = "(Optional) DH group numbers for Phase 1. Valid values are 2, 14-24."
  default     = ["14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"]
}

variable "tunnel_phase1_encryption_algorithms" {
  type        = list(string)
  description = "(Optional) Encryption algorithms for Phase 1. Valid values are AES128, AES256, AES128-GCM-16, AES256-GCM-16."
  default     = ["AES256", "AES256-GCM-16"]
}

variable "tunnel_phase1_integrity_algorithms" {
  type        = list(string)
  description = "(Optional) Integrity algorithms for Phase 1. Valid values are SHA1, SHA2-256, SHA2-384, SHA2-512."
  default     = ["SHA2-256", "SHA2-384", "SHA2-512"]
}

variable "tunnel_phase2_dh_group_numbers" {
  type        = list(string)
  description = "(Optional) DH group numbers for Phase 2. Valid values are 2, 5, 14-24."
  default     = ["14", "15", "16", "17", "18", "19", "20", "21", "22", "23", "24"]
}

variable "tunnel_phase2_encryption_algorithms" {
  type        = list(string)
  description = "(Optional) Encryption algorithms for Phase 2. Valid values are AES128, AES256, AES128-GCM-16, AES256-GCM-16."
  default     = ["AES256", "AES256-GCM-16"]
}

variable "tunnel_phase2_integrity_algorithms" {
  type        = list(string)
  description = "(Optional) Integrity algorithms for Phase 2. Valid values are SHA1, SHA2-256, SHA2-384, SHA2-512."
  default     = ["SHA2-256", "SHA2-384", "SHA2-512"]
}

variable "tunnel_startup_action" {
  type        = string
  description = "(Optional) Action to take when establishing the tunnel. Valid values are add | start. Defaults to add."
  default     = "add"
  validation {
    condition     = can(index(["add", "start"], var.tunnel_startup_action))
    error_message = "tunnel_startup_action must be add or start."
  }
}

###########################
# General
###########################

variable "tags" {
  type        = map(any)
  description = "(Optional) A map of tags to assign to the resources."
  default = {
    created_by = "terraform"
    terraform  = "true"
  }
}
