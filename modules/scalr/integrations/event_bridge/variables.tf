###########################
# Resource Variables
###########################
variable "event_bridge_integrations" {
  description = <<-EOT
    Map of Scalr EventBridge integrations keyed by a caller-supplied logical name. Each entry
    manages one `scalr_event_bridge_integration` resource, creating an Amazon EventBridge event
    source that Scalr can publish run events to.

    Fields:
      - name:           (Required) Name of the EventBridge integration.
      - aws_account_id: (Required) AWS account ID, in the format of a 12-digit account number.
      - region:         (Required) AWS region, e.g. "us-east-1".

    After creation, the caller must accept the resulting event source (exposed via the
    `event_source_name`/`event_source_arn` outputs) as an EventBridge partner event source in
    the target AWS account/region — this module only manages the Scalr side of the pairing.

    Example:
      event_bridge_integrations = {
        default = {
          name           = "via-provider-aws-bridge"
          aws_account_id = "111267354555"
          region         = "us-east-1"
        }
      }
  EOT
  type = map(object({
    name           = string
    aws_account_id = string
    region         = string
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for key, value in var.event_bridge_integrations : can(regex("^[0-9]{12}$", value.aws_account_id))
    ])
    error_message = "Each event_bridge_integrations entry's aws_account_id must be a 12-digit AWS account ID."
  }
}
