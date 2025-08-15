############################################
# General Configuration
############################################

variable "name" {
  type    = string
  default = "default"
}

variable "scope" {
  type    = string
  default = "default"
}

variable "description" {
  type    = string
  default = "default"
}

############################################
# Rule Configuration
############################################

variable "default_action" {
  description = "Default action for the WAF ACL"
  type = object({
    allow = optional(bool)
    block = optional(bool)
  })
  default = {
    allow = false
    block = true
  }
}

variable "rule" {
  description = "Map of rule configuration"
  type = map(object({
    name     = string
    priority = number
    action   = string
    statement = object({
      managed_rule_group_statement = optional(object({
        name           = string
        vendor_name    = string
        priority       = number
        excluded_rules = list(string)
      }))
      not_statement = optional(object({
        ip_set_reference_statement = object({
          arn = string
        })
      }))
      ip_set_reference_statement = optional(object({
        arn = string
      }))
    })
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
  }))
  default = {}
}



############################################
# Visibility Configuration
############################################

variable "visibility_config" {
  description = "Visibility configuration for the WAF ACL"
  type = object({
    cloudwatch_metrics_enabled = optional(bool, true)
    metric_name                = optional(string)
    sampled_requests_enabled   = optional(bool, true)
  })
  default = {
    cloudwatch_metrics_enabled = true
    metric_name                = null
    sampled_requests_enabled   = true
  }
}

############################################
# IP Sets Configuration
############################################

variable "ip_sets" {
  description = "Map of IP sets to create"
  type = map(object({
    name               = string
    description        = optional(string, "IP set created by WAF module")
    ip_address_version = optional(string, "IPV4")
    addresses          = list(string)
  }))
  default = {}
}

############################################
# Association Configuration
############################################

variable "associate_with_resource" {
  description = "Resource ARN to associate the WAF with (API Gateway, ALB, etc.)"
  type        = string
  default     = null
}
