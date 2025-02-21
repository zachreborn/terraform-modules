###########################
# Common Load Balancer Variables
###########################
variable "name_prefix" {
  description = "Name prefix of the load balancer"
  type        = string
}

variable "load_balancer_type" {
  description = "Type of load balancer. Valid values are application, gateway, or network"
  type        = string
  default     = "network"

  validation {
    condition     = contains(["application", "gateway", "network"], var.load_balancer_type)
    error_message = "Valid values for load_balancer_type are (application, gateway, network)."
  }
}

variable "internal" {
  description = "If true, the LB will be internal"
  type        = bool
  default     = false
}

variable "subnet_mappings" {
  description = "A list of subnet mapping configurations with optional values."
  type = list(object({
    subnet_id            = string
    allocation_id        = optional(string, null)
    private_ipv4_address = optional(string, null)
    ipv6_address         = optional(string, null)
  }))
  default = []
}

variable "enable_deletion_protection" {
  description = "If true, deletion of the load balancer will be disabled"
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

variable "enable_zonal_shift" {
  description = "(Optional) Whether zonal shift is enabled. Defaults to false."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

###########################
# Application Load Balancer Variables
###########################
variable "security_groups" {
  description = "List of security group IDs to assign to the LB"
  type        = list(string)
  default     = []
}

variable "client_keep_alive" {
  description = "(Optional) Client keep alive value in seconds. The valid range is 60-604800 seconds. The default is 3600 seconds."
  type        = number
  default     = 3600
}

variable "preserve_host_header" {
  description = "Optional) Whether the Application Load Balancer should preserve the Host header in the HTTP request and send it to the target without any change. Defaults to false."
  type        = bool
  default     = false
}

variable "desync_mitigation_mode" {
  description = "Determines how the load balancer handles requests that might pose a security risk to your application"
  type        = string
  default     = "defensive"
}

variable "connection_logs" {
  description = "(Optional) Connection Logs block. See below. Only valid for Load Balancers of type application."
  type = map(object({
    bucket  = string
    prefix  = string
    enabled = bool
  }))
  default = null
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "enable_http2" {
  description = "Indicates whether HTTP/2 is enabled in application load balancers"
  type        = bool
  default     = true
}

variable "enable_waf_fail_open" {
  description = "Indicates whether to allow a WAF-enabled load balancer to route requests to targets if it is unable to forward the request to AWS WAF"
  type        = bool
  default     = false
}

variable "enable_tls_version_and_cipher_suite_headers" {
  description = "(Optional) Whether the two headers (x-amzn-tls-version and x-amzn-tls-cipher-suite), which contain information about the negotiated TLS version and cipher suite, are added to the client request before sending it to the target. Only valid for Load Balancers of type application. Defaults to false"
  type        = bool
  default     = false
}

variable "enable_xff_client_port" {
  description = "(Optional) Whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in application load balancers. Defaults to false."
  type        = bool
  default     = false
}

variable "xff_header_processing_mode" {
  description = "(Optional) Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target. The possible values are append, preserve, and remove. Only valid for Load Balancers of type application. The default is append."
  type        = string
  default     = "append"
}

variable "drop_invalid_header_fields" {
  description = "Indicates whether invalid header fields are dropped in application load balancers"
  type        = bool
  default     = false
}

###########################
# Network Load Balancer Variables
###########################
variable "enable_cross_zone_load_balancing" {
  description = "If true, cross-zone load balancing of the load balancer will be enabled"
  type        = bool
  default     = false
}

variable "access_logs" {
  description = "Access logs configuration for the LB"
  type = map(object({
    bucket  = string
    prefix  = string
    enabled = bool
  }))
  default = null
}

variable "dns_record_client_routing_policy" {
  description = "(Optional) How traffic is distributed among the load balancer Availability Zones. Possible values are any_availability_zone (default), availability_zone_affinity, or partial_availability_zone_affinity. See Availability Zone DNS affinity for additional details. Only valid for network type load balancers."
  type        = string
  default     = "any_availability_zone"
}

variable "enforce_security_group_inbound_rules_on_private_link_traffic" {
  description = "(Optional) Whether inbound security group rules are enforced for traffic originating from a PrivateLink. Only valid for Load Balancers of type network. The possible values are on and off."
  type        = string
  default     = null
}

###########################
# Target Group Variables
###########################

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    name                               = string
    port                               = number
    protocol                           = string
    target_type                        = string
    vpc_id                             = string
    deregistration_delay               = optional(number)
    slow_start                         = optional(number)
    load_balancing_algorithm_type      = optional(string)
    target_group_proxy_protocol_v2     = optional(bool)
    target_group_preserve_client_ip    = optional(bool)
    protocol_version                   = optional(string)
    connection_termination             = optional(bool)
    lambda_multi_value_headers_enabled = optional(bool)
    health_check = map(object({
      enabled              = optional(bool, true)
      healthy_threshold    = optional(number, 3)
      interval             = optional(number, 30)
      matcher              = optional(string)
      path                 = optional(string)
      port                 = optional(string, "traffic-port")
      protocol             = optional(string, "HTTP")
      timeout              = optional(number, 5)
      unhealthy_threshold  = optional(number, 3)
      success_codes        = optional(string)
      grace_period_seconds = optional(number)
    }))

    stickiness = set(object({
      type            = string
      cookie_duration = optional(number)
      cookie_name     = optional(string)
    }))

    tags = optional(map(string), {})
  }))
  default = {}
}

###########################
# Listener Variables
###########################
variable "listeners" {
  description = "Map of listener configurations"
  type = map(object({
    port            = number
    protocol        = string
    ssl_policy      = optional(string)
    certificate_arn = optional(string)
    alpn_policy     = optional(string)

    authenticate_oidc = optional(object({
      authorization_endpoint = string
      client_id              = string
      client_secret          = string
      issuer                 = string
      token_endpoint         = string
      user_info_endpoint     = string
    }))

    authenticate_cognito = optional(object({
      user_pool_arn       = string
      user_pool_client_id = string
      user_pool_domain    = string
    }))

    mutual_authentication = optional(object({
      mode = string # Only valid field, can be "verify" or "strict"
    }))

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

      http_header = optional(map(object({
        http_header_name = string
        values           = list(string)
      })))

      path_pattern = optional(object({
        values = list(string)
      }))

      query_string = optional(map(object({
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
