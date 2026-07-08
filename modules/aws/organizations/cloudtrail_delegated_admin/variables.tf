############################################################
# AWS CloudTrail Organization Delegated Administrator
############################################################

variable "account_id" {
  description = "(Required) An AWS Organizations member account ID to designate as the CloudTrail delegated administrator. Must be called from the organization's management account. Registering via this CloudTrail-native resource (rather than the generic modules/aws/organizations/delegated_admin module) also creates the AWSServiceRoleForCloudTrail and AWSServiceRoleForCloudTrailEventContext service-linked roles, which registration through the Organizations API alone does not create."
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "The value must be a 12-digit AWS account ID."
  }
}

############################################################
# General Variables
############################################################
