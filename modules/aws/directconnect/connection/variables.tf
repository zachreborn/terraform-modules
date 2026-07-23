###########################
# Direct Connect Connection
###########################

variable "name" {
  description = "(Required) The name of the Direct Connect connection."
  type        = string
}

variable "bandwidth" {
  description = "(Required) The bandwidth of the connection. Valid values for dedicated connections: 1Gbps, 10Gbps, 100Gbps. Valid values for hosted connections: 50Mbps, 100Mbps, 200Mbps, 300Mbps, 400Mbps, 500Mbps, 1Gbps, 2Gbps, 5Gbps, 10Gbps, 25Gbps. Case sensitive."
  type        = string
}

variable "location" {
  description = "(Required) The AWS Direct Connect location where the connection is located. Use the locationCode value from describe-locations."
  type        = string
}

variable "encryption_mode" {
  description = "(Optional) The connection MAC Security (MACsec) encryption mode. Only available on dedicated connections. Valid values: no_encrypt, should_encrypt, must_encrypt."
  type        = string
  default     = "no_encrypt"
  validation {
    condition     = contains(["no_encrypt", "should_encrypt", "must_encrypt"], var.encryption_mode)
    error_message = "encryption_mode must be one of: no_encrypt, should_encrypt, must_encrypt."
  }
}

variable "provider_name" {
  description = "(Optional) The name of the service provider (carrier) associated with the connection."
  type        = string
  default     = null
}

variable "request_macsec" {
  description = "(Optional) Whether to request MAC Security (MACsec) on the connection. Only supported on dedicated connections."
  type        = bool
  default     = false
}

variable "skip_destroy" {
  description = "(Optional) Set to true to remove the connection from Terraform state on destroy without deleting the physical circuit. Useful for decommissioning workflows where the circuit must be cancelled out-of-band."
  type        = bool
  default     = false
}

###########################
# Tags
###########################

variable "tags" {
  description = "(Optional) Map of tags to assign to the connection. A Name tag is automatically added from var.name."
  type        = map(string)
  default     = {}
}
