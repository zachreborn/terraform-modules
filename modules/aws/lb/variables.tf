variable "name" {
  description = "Name of the load balancer"
  type        = string
}

variable "internal" {
  description = "If true, the LB will be internal"
  type        = bool
  default     = false
}

variable "load_balancer_type" {
  description = "Type of load balancer. Valid values are application or network"
  type        = string
  default     = "network"

  validation {
    condition     = contains(["application", "network"], var.load_balancer_type)
    error_message = "Valid values for load_balancer_type are (application, network)."
  }
}

variable "security_groups" {
  description = "List of security group IDs to assign to the LB"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = "List of subnet IDs to attach to the LB"
  type        = list(string)
  default     = []
}

variable "subnet_mappings" {
  description = "List of subnet mapping configurations"
  type        = list(map(string))
  default     = []
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled"
  type        = bool
  default     = false
}

variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing of the load balancer will be enabled"
  type        = bool
  default     = false
}

variable "customer_owned_ipv4_pool" {
  description = "The ID of the customer owned ipv4 pool to use for this load balancer"
  type        = string
  default     = null
}

variable "ip_address_type" {
  description = "The type of IP addresses used by the subnets for your load balancer"
  type        = string
  default     = "ipv4"
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests that might pose a security risk to your application"
  type        = string
  default     = "defensive"
}

variable "access_logs" {
  description = "Access logs configuration for the LB"
  type = object({
    bucket  = string
    prefix  = string
    enabled = bool
  })
  default = null
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "target_groups" {
  description = "Map of target group configurations"
  type        = any
  default     = {}
}

variable "listeners" {
  description = "Map of listener configurations"
  type        = any
  default     = {}
}

variable "listener_rules" {
  description = "Map of listener rule configurations"
  type        = any
  default     = {}
}
