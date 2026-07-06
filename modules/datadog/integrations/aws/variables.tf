###########################
# Resource Variables
###########################
variable "aws_accounts" {
  description = "Map of AWS account integrations keyed by a logical name. Each entry creates one Datadog - AWS account integration. Contains sensitive fields (secret_access_key)."
  type = map(object({
    aws_account_id     = string
    aws_partition      = string
    account_tags       = optional(list(string), [])
    create_external_id = optional(bool, false)

    auth_config = object({
      aws_auth_config_role = optional(object({
        role_name   = string
        external_id = optional(string)
      }))
      aws_auth_config_keys = optional(object({
        access_key_id     = string
        secret_access_key = string
      }))
    })

    aws_regions = optional(object({
      include_all  = optional(bool, true)
      include_only = optional(list(string))
    }), {})

    logs_config = optional(object({
      lambda_forwarder = optional(object({
        lambdas = optional(list(string), [])
        sources = optional(list(string), [])
        log_source_config = optional(object({
          tag_filters = optional(list(object({
            source = string
            tags   = list(string)
          })), [])
        }))
      }), {})
    }), {})

    metrics_config = optional(object({
      automute_enabled          = optional(bool, true)
      collect_cloudwatch_alarms = optional(bool, false)
      collect_custom_metrics    = optional(bool, false)
      enabled                   = optional(bool, true)
      namespace_filters = optional(object({
        exclude_only = optional(list(string))
        include_only = optional(list(string))
      }), {})
      tag_filters = optional(list(object({
        namespace = string
        tags      = optional(list(string), [])
      })), [])
    }), {})

    resources_config = optional(object({
      cloud_security_posture_management_collection = optional(bool, false)
      extended_collection                          = optional(bool, true)
    }), {})

    traces_config = optional(object({
      xray_services = optional(object({
        include_all  = optional(bool)
        include_only = optional(list(string))
      }), {})
    }), {})
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.aws_accounts : (
        (v.auth_config.aws_auth_config_role != null) != (v.auth_config.aws_auth_config_keys != null)
      )
    ])
    error_message = "Each aws_account entry must specify exactly one of auth_config.aws_auth_config_role or auth_config.aws_auth_config_keys, not both and not neither."
  }
}
