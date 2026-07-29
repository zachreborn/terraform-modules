###########################
# Connection Configuration
###########################

variable "connection_name" {
  type        = string
  description = "(Required) The name of the connection."
}

variable "location" {
  type        = string
  description = "(Required) The AWS Direct Connect location where the connection is located. See DescribeLocations for the list of AWS Direct Connect locations. Use locationCode."
}

variable "bandwidth" {
  type        = string
  description = "(Required) The bandwidth of the connection. Valid values for dedicated connections: 1Gbps, 10Gbps, 100Gbps. Valid values for hosted connections: 50Mbps, 100Mbps, 200Mbps, 300Mbps, 400Mbps, 500Mbps, 1Gbps, 2Gbps, 5Gbps, 10Gbps."
}

variable "request_macsec" {
  type        = bool
  description = "(Optional) Request MACsec encryption on the connection. MACsec is available only on dedicated connections. Defaults to false."
  default     = false
}

variable "skip_destroy" {
  type        = bool
  description = "(Optional) Set to true to prevent Terraform from deleting the connection if there are virtual interfaces. The connection may only be deleted when empty."
  default     = true
}

variable "provider_name" {
  type        = string
  description = "(Optional) The name of the service provider associated with the connection."
  default     = null
}

variable "encryption_mode" {
  type        = string
  description = "(Optional) The MACsec encryption mode for the connection. Valid values are must_encrypt, should_encrypt, or no_encrypt. Only applicable when request_macsec is true; defaults to AWS's standard behavior when unset."
  default     = null
  validation {
    condition     = var.encryption_mode == null || can(index(["must_encrypt", "should_encrypt", "no_encrypt"], var.encryption_mode))
    error_message = "encryption_mode must be must_encrypt, should_encrypt, or no_encrypt."
  }
}

variable "tags" {
  type        = map(any)
  description = "(Optional) A map of tags to assign to the connection."
  default = {
    created_by = "terraform"
    terraform  = "true"
  }
}
