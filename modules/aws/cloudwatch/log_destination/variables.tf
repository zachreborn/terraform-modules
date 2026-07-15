###########################
# Log Destination Variables
###########################

variable "destination_name" {
  description = "(Required) A name for the log destination."
  type        = string
}

variable "destination_target_arn" {
  description = "(Required) The ARN of the target Amazon resource (e.g. a Kinesis stream or Kinesis Firehose delivery stream) that the log destination delivers matching log events to."
  type        = string
}

variable "destination_role_arn" {
  description = "(Required) The ARN of an IAM role that grants CloudWatch Logs permission to write to the target ARN (destination_target_arn). Supplied by the caller (e.g. from the modules/aws/iam/role module)."
  type        = string
}

variable "destination_policy_access_policy" {
  description = "(Optional) The cross-account access policy document (JSON) attached to the log destination via aws_cloudwatch_log_destination_policy. When null, no destination policy resource is created."
  type        = string
  default     = null

  validation {
    condition     = var.destination_policy_access_policy == null ? true : can(jsondecode(var.destination_policy_access_policy))
    error_message = "destination_policy_access_policy must be valid JSON when set."
  }
}

variable "destination_policy_force_update" {
  description = "(Optional) Whether to update the access policy on the log destination even if the destination is currently in use. Maps to the force_update argument of aws_cloudwatch_log_destination_policy."
  type        = bool
  default     = null
}

variable "tags" {
  description = "(Optional) A map of tags to assign to the log destination. A Name tag is merged in automatically from destination_name."
  type        = map(string)
  default     = {}
}
