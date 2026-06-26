###########################
# Resource Variables
###########################

variable "ccm_configs" {
  description = "Map of Cloud Cost Management (CCM) configurations to create. Each key is a logical name. The value's aws_account_config_id is the Datadog-internal UUID from the AWS integration resource (not the AWS account ID)."
  type = map(object({
    aws_account_config_id = string
    ccm_config = optional(object({
      data_export_configs = optional(list(object({
        bucket_name   = optional(string, null)
        bucket_region = optional(string, null)
        report_name   = optional(string, null)
        report_prefix = optional(string, null)
        report_type   = optional(string, null)
      })), null)
    }), null)
  }))
}
