############################################
# General Configuration
############################################

variable "description" {
  description = "A friendly description of the WebACL."
  type        = string
  default     = "WAF WebACL managed by Terraform"
}

variable "name" {
  description = "A friendly name of the WebACL. Must be unique within the AWS region."
  type        = string
}

variable "scope" {
  description = "Specifies whether this is for an AWS CloudFront distribution or a regional application. Valid values are CLOUDFRONT or REGIONAL."
  type        = string
  default     = "REGIONAL"
  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "The scope must be either 'REGIONAL' or 'CLOUDFRONT'."
  }
}

variable "tags" {
  description = "A map of tags to assign to all resources."
  type        = map(string)
  default     = {}
}

############################################
# Rule Configuration
############################################

variable "default_action" {
  description = "The action to perform if none of the rules contained in the WebACL match. Valid values are 'allow' or 'block'."
  type        = string
  default     = "block"
  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "The default_action must be either 'allow' or 'block'."
  }
}

variable "rule" {
  description = "Map of rules to configure on the WAF WebACL. Use 'action' for IP set and regex rules; use 'override_action' for managed rule group rules."
  type = map(object({
    name            = string
    priority        = number
    action          = optional(string) # "allow", "block", or "count" — used for non-managed-rule-group statements
    override_action = optional(string) # "none" or "count" — used with managed_rule_group_statement
    statement = object({
      managed_rule_group_statement = optional(object({
        name                  = string
        vendor_name           = string
        rule_action_overrides = optional(list(string), []) # rule names to override to count mode
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
    captcha_config = optional(object({
      immunity_time_property = optional(object({
        immunity_time = optional(number, 300)
      }), { immunity_time = 300 })
    }), { immunity_time_property = { immunity_time = 300 } })
    challenge_config = optional(object({
      immunity_time_property = optional(object({
        immunity_time = optional(number, 300)
      }), { immunity_time = 300 })
    }), { immunity_time_property = { immunity_time = 300 } })
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
  description = "Visibility configuration for the WAF ACL. metric_name defaults to the WAF name if not specified."
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
  description = "Map of IP sets to create and manage alongside the WAF WebACL."
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
  description = "The ARN of the resource to associate with the web ACL. Supported resources include ALB, API Gateway REST API, AppSync GraphQL API, or Cognito user pool."
  type        = string
  default     = null
}
