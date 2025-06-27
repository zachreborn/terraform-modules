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
