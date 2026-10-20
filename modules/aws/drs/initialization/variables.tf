###########################
# Resource Variables
###########################

variable "additional_policy_arns" {
  type        = map(list(string))
  description = "(Optional) Extra managed policy ARNs to attach on top of the AWS managed policies this module already attaches, keyed by DRS role name. Keys must be one of the six role names this module manages."
  default     = {}

  validation {
    condition = alltrue([
      for role_name in keys(var.additional_policy_arns) : contains([
        "AWSElasticDisasterRecoveryAgentRole",
        "AWSElasticDisasterRecoveryConversionServerRole",
        "AWSElasticDisasterRecoveryFailbackRole",
        "AWSElasticDisasterRecoveryRecoveryInstanceRole",
        "AWSElasticDisasterRecoveryRecoveryInstanceWithLaunchActionsRole",
        "AWSElasticDisasterRecoveryReplicationServerRole",
      ], role_name)
    ])
    error_message = "Each additional_policy_arns key must name one of the six Elastic Disaster Recovery service roles this module manages."
  }
}

variable "create_service_linked_role" {
  type        = bool
  description = "(Optional) Whether to create the AWSServiceRoleForElasticDisasterRecovery service-linked role. Set this to false in an account where the role already exists, since AWS allows only one service-linked role per service per account."
  default     = true
}

variable "create_service_roles" {
  type        = bool
  description = "(Optional) Whether to create the six Elastic Disaster Recovery service roles and their instance profiles. Set this to false in an account that has already been initialized through the DRS console, since the role names are fixed and would otherwise collide."
  default     = true
}

variable "max_session_duration" {
  type        = number
  description = "(Optional) Maximum session duration, in seconds, for each Elastic Disaster Recovery service role. Must be between 3600 and 43200."
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "The max_session_duration must be between 3600 and 43200 seconds (1 hour to 12 hours)."
  }
}

variable "path" {
  type        = string
  description = "(Optional) IAM path applied to the Elastic Disaster Recovery service roles and instance profiles. AWS documents /service-role/ for these roles; changing it is not recommended."
  default     = "/service-role/"

  validation {
    condition     = startswith(var.path, "/") && endswith(var.path, "/")
    error_message = "The path must begin and end with a forward slash."
  }
}

variable "permissions_boundary" {
  type        = string
  description = "(Optional) ARN of the policy used to set the permissions boundary on each Elastic Disaster Recovery service role."
  default     = null
}

variable "service_linked_role_description" {
  type        = string
  description = "(Optional) Description applied to the AWSServiceRoleForElasticDisasterRecovery service-linked role."
  default     = "Service-linked role for AWS Elastic Disaster Recovery."
}

###########################
# General Variables
###########################

variable "tags" {
  type        = map(string)
  description = "(Optional) A map of tags merged with a Name tag and applied to each role, instance profile, and the service-linked role."
  default = {
    terraform = "true"
  }
}
