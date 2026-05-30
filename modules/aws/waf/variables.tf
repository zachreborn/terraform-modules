############################################
# General Configuration
############################################

variable "description" {
  description = "A friendly description of the WebACL."
  type        = string
  default     = "WAF WebACL managed by Terraform"
}

variable "token_domains" {
  description = "Specifies the domains to use for CAPTCHA and Challenge token sharing. Required when using CAPTCHA or Challenge across multiple domains."
  type        = list(string)
  default     = null
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

variable "custom_response_body" {
  description = "Map of custom response bodies that can be referenced by custom_response block actions. Key is the unique response body key used in rule actions."
  type = map(object({
    content      = string
    content_type = string
  }))
  default = {}
  validation {
    condition     = alltrue([for v in values(var.custom_response_body) : contains(["TEXT_PLAIN", "TEXT_HTML", "APPLICATION_JSON"], v.content_type)])
    error_message = "content_type must be one of TEXT_PLAIN, TEXT_HTML, or APPLICATION_JSON."
  }
}

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
      ############################
      # Managed Rule Group
      ############################
      managed_rule_group_statement = optional(object({
        name        = string
        vendor_name = string
        # BREAKING CHANGE: was list(string), now map keyed by rule name
        rule_action_overrides = optional(map(object({
          action = string # allow, block, count, captcha, or challenge
        })), {})
        # Scope down to a subset of requests; accepts any leaf statement shape
        scope_down_statement = optional(any)
      }))

      ############################
      # IP Set Reference
      ############################
      ip_set_reference_statement = optional(object({
        arn = string
      }))

      ############################
      # Geo Match
      ############################
      geo_match_statement = optional(object({
        country_codes = list(string)
        forwarded_ip_config = optional(object({
          header_name       = string
          fallback_behavior = string # MATCH or NO_MATCH
        }))
      }))

      ############################
      # Rate Based
      ############################
      rate_based_statement = optional(object({
        limit                 = number
        aggregate_key_type    = string           # IP, CONSTANT, FORWARDED_IP
        evaluation_window_sec = optional(number) # 60, 120, 300, or 600
        forwarded_ip_config = optional(object({
          header_name       = string
          fallback_behavior = string
        }))
        # Scope down to a subset of requests; accepts any leaf statement shape
        scope_down_statement = optional(any)
      }))

      ############################
      # Byte Match
      ############################
      byte_match_statement = optional(object({
        positional_constraint = string # EXACTLY, STARTS_WITH, ENDS_WITH, CONTAINS, CONTAINS_WORD
        search_string         = string
        field_to_match = object({
          all_query_arguments   = optional(bool, false)
          body                  = optional(object({ oversize_handling = optional(string, "CONTINUE") }))
          method                = optional(bool, false)
          query_string          = optional(bool, false)
          uri_path              = optional(bool, false)
          single_header         = optional(object({ name = string }))
          single_query_argument = optional(object({ name = string }))
          headers = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_headers = optional(list(string), [])
              excluded_headers = optional(list(string), [])
            })
            match_scope       = string # ALL, KEY, or VALUE
            oversize_handling = string # CONTINUE, MATCH, or NO_MATCH
          }))
          cookies = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_cookies = optional(list(string), [])
              excluded_cookies = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
        })
        text_transformation = list(object({
          priority = number
          type     = string
        }))
      }))

      ############################
      # Size Constraint
      ############################
      size_constraint_statement = optional(object({
        comparison_operator = string # EQ, NE, LE, LT, GE, GT
        size                = number
        field_to_match = object({
          all_query_arguments   = optional(bool, false)
          body                  = optional(object({ oversize_handling = optional(string, "CONTINUE") }))
          method                = optional(bool, false)
          query_string          = optional(bool, false)
          uri_path              = optional(bool, false)
          single_header         = optional(object({ name = string }))
          single_query_argument = optional(object({ name = string }))
          headers = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_headers = optional(list(string), [])
              excluded_headers = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
          cookies = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_cookies = optional(list(string), [])
              excluded_cookies = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
        })
        text_transformation = list(object({
          priority = number
          type     = string
        }))
      }))

      ############################
      # SQLi Match
      ############################
      sqli_match_statement = optional(object({
        sensitivity_level = optional(string, "LOW") # LOW or HIGH
        field_to_match = object({
          all_query_arguments   = optional(bool, false)
          body                  = optional(object({ oversize_handling = optional(string, "CONTINUE") }))
          method                = optional(bool, false)
          query_string          = optional(bool, false)
          uri_path              = optional(bool, false)
          single_header         = optional(object({ name = string }))
          single_query_argument = optional(object({ name = string }))
          headers = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_headers = optional(list(string), [])
              excluded_headers = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
          cookies = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_cookies = optional(list(string), [])
              excluded_cookies = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
        })
        text_transformation = list(object({
          priority = number
          type     = string
        }))
      }))

      ############################
      # XSS Match
      ############################
      xss_match_statement = optional(object({
        field_to_match = object({
          all_query_arguments   = optional(bool, false)
          body                  = optional(object({ oversize_handling = optional(string, "CONTINUE") }))
          method                = optional(bool, false)
          query_string          = optional(bool, false)
          uri_path              = optional(bool, false)
          single_header         = optional(object({ name = string }))
          single_query_argument = optional(object({ name = string }))
          headers = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_headers = optional(list(string), [])
              excluded_headers = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
          cookies = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_cookies = optional(list(string), [])
              excluded_cookies = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
        })
        text_transformation = list(object({
          priority = number
          type     = string
        }))
      }))

      ############################
      # Regex Match
      ############################
      regex_match_statement = optional(object({
        regex_string = string
        field_to_match = object({
          all_query_arguments   = optional(bool, false)
          body                  = optional(object({ oversize_handling = optional(string, "CONTINUE") }))
          method                = optional(bool, false)
          query_string          = optional(bool, false)
          uri_path              = optional(bool, false)
          single_header         = optional(object({ name = string }))
          single_query_argument = optional(object({ name = string }))
          headers = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_headers = optional(list(string), [])
              excluded_headers = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
          cookies = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_cookies = optional(list(string), [])
              excluded_cookies = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
        })
        text_transformation = list(object({
          priority = number
          type     = string
        }))
      }))

      ############################
      # Regex Pattern Set Reference
      ############################
      regex_pattern_set_reference_statement = optional(object({
        arn = string
        field_to_match = object({
          all_query_arguments   = optional(bool, false)
          body                  = optional(object({ oversize_handling = optional(string, "CONTINUE") }))
          method                = optional(bool, false)
          query_string          = optional(bool, false)
          uri_path              = optional(bool, false)
          single_header         = optional(object({ name = string }))
          single_query_argument = optional(object({ name = string }))
          headers = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_headers = optional(list(string), [])
              excluded_headers = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
          cookies = optional(object({
            match_pattern = object({
              all              = optional(bool, false)
              included_cookies = optional(list(string), [])
              excluded_cookies = optional(list(string), [])
            })
            match_scope       = string
            oversize_handling = string
          }))
        })
        text_transformation = list(object({
          priority = number
          type     = string
        }))
      }))

      ############################
      # Label Match
      ############################
      label_match_statement = optional(object({
        key   = string
        scope = string # LABEL or NAMESPACE
      }))

      ############################
      # Rule Group Reference
      ############################
      rule_group_reference_statement = optional(object({
        arn = string
        rule_action_overrides = optional(map(object({
          action = string # allow, block, count, captcha, or challenge
        })), {})
      }))

      ############################
      # Compound Statements (1 level deep)
      # For deeper nesting use rule_group_reference_statement
      ############################
      not_statement = optional(object({
        # Accepts any leaf statement shape; use try() to access fields safely
        statement = any
      }))

      and_statement = optional(object({
        # List of leaf statement objects; each should contain exactly one statement type key
        statements = list(any)
      }))

      or_statement = optional(object({
        # List of leaf statement objects; each should contain exactly one statement type key
        statements = list(any)
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
# ACL-Level Captcha and Challenge Configuration
############################################

variable "captcha_config" {
  description = "Specifies how AWS WAF should handle CAPTCHA evaluations at the Web ACL level."
  type = object({
    immunity_time_property = optional(object({
      immunity_time = optional(number, 300)
    }), { immunity_time = 300 })
  })
  default = null
}

variable "challenge_config" {
  description = "Specifies how AWS WAF should handle Challenge evaluations at the Web ACL level."
  type = object({
    immunity_time_property = optional(object({
      immunity_time = optional(number, 300)
    }), { immunity_time = 300 })
  })
  default = null
}

############################################
# Logging Configuration
############################################

variable "logging_configuration" {
  description = "WAF logging configuration. Set log_destination_configs to a list of Kinesis Firehose, CloudWatch Logs, or S3 ARNs. redacted_fields and logging_filter are optional."
  type = object({
    log_destination_configs = list(string)
    redacted_fields = optional(list(object({
      single_header = optional(object({ name = string }))
      uri_path      = optional(object({}))
      query_string  = optional(object({}))
      method        = optional(object({}))
    })), [])
    logging_filter = optional(object({
      default_behavior = string
      filter = list(object({
        behavior    = string
        requirement = string
        condition = list(object({
          action_condition     = optional(object({ action = string }))
          label_name_condition = optional(object({ label_name = string }))
        }))
      }))
    }))
  })
  default = null
}

############################################
# Association Configuration
############################################

variable "association_config" {
  description = "Specifies custom configurations for the associations between the web ACL and protected resources. Controls request body inspection size limits per resource type."
  type = object({
    request_body = optional(object({
      api_gateway = optional(object({
        default_size_inspection_limit = optional(string, "KB_16")
      }))
      app_runner_service = optional(object({
        default_size_inspection_limit = optional(string, "KB_16")
      }))
      cognito_user_pool = optional(object({
        default_size_inspection_limit = optional(string, "KB_16")
      }))
      verified_access_instance = optional(object({
        default_size_inspection_limit = optional(string, "KB_16")
      }))
    }))
  })
  default = null
}

variable "associate_with_resource" {
  description = "The ARN of the resource to associate with the web ACL. Supported resources include ALB, API Gateway REST API, AppSync GraphQL API, or Cognito user pool."
  type        = string
  default     = null
}
