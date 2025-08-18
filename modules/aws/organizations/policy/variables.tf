############################################################
# AWS Organization Policy Variables
############################################################

variable "content" {
  description = "(Required) The content of the AWS Organization's policy in JSON format."
  type        = string
  # Example:
  # content = jsonencode({
  #   Version = "2012-10-17",
  #   Statement = [
  #     {
  #       Effect = "Allow",
  #       Action = "organizations:DescribeOrganization",
  #       Resource = "*"
  #     }
  #   ]
  # })
}

variable "description" {
  description = "(Optional) A description of the AWS Organization's policy."
  type        = string
  default     = null
}

variable "name" {
  description = "(Required) The name of the AWS Organization's policy."
  type        = string
}

variable "skip_destroy" {
  description = "(Optional) If true, the policy will not be destroyed when the resource is removed from the configuration. Defaults to false."
  type        = bool
  default     = false
}

variable "type" {
  description = "(Required) The type of the AWS Organization's policy. Valid values are 'AISERVICES_OPT_OUT_POLICY','BACKUP_POLICY', 'RESOURCE_CONTROL_POLICY', 'SERVICE_CONTROL_POLICY', and 'TAG_POLICY'."
  type        = string
  validation {
    condition     = contains(["AISERVICES_OPT_OUT_POLICY", "BACKUP_POLICY", "RESOURCE_CONTROL_POLICY", "SERVICE_CONTROL_POLICY", "TAG_POLICY"], var.type)
    error_message = "The type must be one of: AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, RESOURCE_CONTROL_POLICY, SERVICE_CONTROL_POLICY, TAG_POLICY."
  }
}

############################################################
# General Variables
############################################################

variable "tags" {
  description = "(Optional) A map of tags to assign to the AWS Organization's policy. Tags are key-value pairs that help organize and manage resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
