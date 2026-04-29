######################################
# # VPC DHCP Options Variables
######################################
variable "domain_name" {
  description = "(Optional) Define the domain name for the DHCP Options Set"
  type        = string
  default     = null
}

variable "domain_name_servers" {
  description = "(Optional) List of IP addresses for the DNS servers"
  type        = list(string)
  default     = []
}

variable "ntp_servers" {
  description = "(Optional) List of IP addresses for the NTP servers"
  type        = list(string)
  default     = []
}

variable "netbios_name_servers" {
  description = "(Optional) List of NETBIOS name servers."
  type        = list(string)
  default     = []
}

variable "netbios_node_type" {
  description = "(Optional) The NetBIOS node type (1, 2, 4, or 8). AWS recommends to specify 2 since broadcast and multicast are not supported in their network. For more information about these node types, see RFC 2132."
  type        = string
  default     = null
}

variable "tags" {
  description = "(Optional) A mapping of tags to assign to the object."
  default = {
    Name        = "DHCP Options Set"
    terraform   = "true"
    created_by  = "Terraform"
    environment = "prod"
    description = "DHCP Option Set for the VPC"
  }
}

variable "vpc_id" {
  description = "(Required) ID of the VPC to attach the DHCP Options Set to"
  type        = string
}
