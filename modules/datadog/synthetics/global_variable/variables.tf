###########################
# Resource Variables
###########################
variable "global_variables" {
  description = "Map of Synthetics global variable configurations keyed by logical name. The 'value' field may contain sensitive data — enable Terraform state encryption when storing secrets."
  type = map(object({
    name             = string
    description      = optional(string, "")
    tags             = optional(list(string), [])
    value            = optional(string, null)
    value_wo_version = optional(string, null)
    secure           = optional(bool, false)
    is_totp          = optional(bool, false)
    is_fido          = optional(bool, false)
    restricted_roles = optional(set(string), null)
    parse_test_id    = optional(string, null)

    options = optional(object({
      totp_parameters = optional(object({
        digits           = number
        refresh_interval = number
      }), null)
    }), null)

    parse_test_options = optional(object({
      type                = string
      field               = optional(string, null)
      local_variable_name = optional(string, null)
      parser = optional(object({
        type  = string
        value = optional(string, null)
      }), null)
    }), null)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.global_variables :
      v.parse_test_options == null || contains(["http_body", "http_header", "http_status_code", "local_variable"], v.parse_test_options.type)
    ])
    error_message = "parse_test_options.type must be one of: http_body, http_header, http_status_code, local_variable."
  }

  validation {
    condition = alltrue([
      for k, v in var.global_variables :
      v.parse_test_options == null || v.parse_test_options.parser == null ||
      contains(["raw", "json_path", "regex", "x_path"], v.parse_test_options.parser.type)
    ])
    error_message = "parse_test_options.parser.type must be one of: raw, json_path, regex, x_path."
  }
}
