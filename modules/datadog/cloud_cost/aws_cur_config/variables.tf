###########################
# Resource Variables
###########################

variable "aws_cur_configs" {
  description = "Map of AWS Cost and Usage Report (CUR) configurations to create. Each key is a logical name for the configuration."
  type = map(object({
    account_id    = string
    bucket_name   = string
    report_name   = string
    report_prefix = string
    bucket_region = optional(string, null)
    account_filters = optional(object({
      include_new_accounts = optional(bool, null)
      excluded_accounts    = optional(list(string), null)
      included_accounts    = optional(list(string), null)
    }), null)
  }))
}
