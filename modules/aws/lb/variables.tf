# Load Balancer Variables
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

# Target Group Variables
variable "target_group_name" {
  description = "Name of the target group"
  type        = string
  default     = null
}

variable "target_group_name_prefix" {
  description = "Prefix for the target group name"
  type        = string
  default     = null
}

variable "target_group_port" {
  description = "Port on which targets receive traffic"
  type        = number
}

variable "target_group_protocol" {
  description = "Protocol to use for routing traffic to the targets"
  type        = string
}

variable "target_group_vpc_id" {
  description = "Identifier of the VPC in which to create the target group"
  type        = string
}

variable "target_group_target_type" {
  description = "Type of target that you must specify when registering targets with this target group"
  type        = string
  default     = "instance"
}

variable "target_group_deregistration_delay" {
  description = "Amount of time to wait for in-flight requests to complete before deregistering a target"
  type        = number
  default     = 300
}

variable "target_group_slow_start" {
  description = "Amount of time for targets to warm up before the load balancer sends them a full share of requests"
  type        = number
  default     = 0
}

variable "target_group_proxy_protocol_v2" {
  description = "Whether to enable support for proxy protocol v2"
  type        = bool
  default     = false
}

variable "target_group_load_balancing_algorithm_type" {
  description = "Determines how the load balancer selects targets when routing requests"
  type        = string
  default     = null
}

variable "target_group_preserve_client_ip" {
  description = "Whether client IP preservation is enabled"
  type        = bool
  default     = null
}

# The target_groups variable should now only contain the nested objects
variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    health_check = optional(object({
      enabled             = optional(bool, true)
      healthy_threshold   = optional(number, 3)
      interval            = optional(number, 30)
      matcher             = optional(string)
      path                = optional(string)
      port                = optional(string, "traffic-port")
      protocol            = optional(string, "HTTP")
      timeout             = optional(number, 5)
      unhealthy_threshold = optional(number, 3)
    }))

    stickiness = optional(object({
      type            = string
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))

    tags = optional(map(string), {})
  }))
  default = {}
}

# Listener Variables
variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)

    default_action = object({
      type             = string
      target_group_arn = optional(string)

      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = optional(string)
      }))

      redirect = optional(object({
        path        = optional(string)
        host        = optional(string)
        port        = optional(string)
        protocol    = optional(string)
        query       = optional(string)
        status_code = string
      }))
    })
  }))
  default = {}
}

# Listener Rule Variables
variable "listener_rules" {
  description = "Map of listener rule configurations"
  type = map(object({
    listener_key = string
    priority     = optional(number)

    action = object({
      type             = string
      target_group_arn = optional(string)

      fixed_response = optional(object({
        content_type = string
        message_body = optional(string)
        status_code  = optional(string)
      }))

      redirect = optional(object({
        path        = optional(string)
        host        = optional(string)
        port        = optional(string)
        protocol    = optional(string)
        query       = optional(string)
        status_code = string
      }))
    })

    conditions = list(object({
      host_header = optional(object({
        values = list(string)
      }))

      http_header = optional(object({
        http_header_name = string
        values           = list(string)
      }))

      path_pattern = optional(object({
        values = list(string)
      }))

      query_string = optional(list(object({
        key   = optional(string)
        value = string
      })))

      source_ip = optional(object({
        values = list(string)
      }))
    }))
  }))
  default = {}
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}
