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
      managed_rule_group_statement = object({
        name           = string
        vendor_name    = string
        priority       = number
        excluded_rules = list(string)
      })
    })
    visibility_config = object({
      cloudwatch_metrics_enabled = bool
      metric_name                = string
      sampled_requests_enabled   = bool
    })
  }))
}



############################################
# Visibility Configuration
############################################

variable "visibility_config.cloudwatch_metrics_enabled" {
  type    = bool
  default = true
}

variable "visibility_config.metric_name" {
  type    = string
  default = var.name
}

variable "visibility_config.sampled_requests_enabled" {
  type    = bool
  default = true
}
