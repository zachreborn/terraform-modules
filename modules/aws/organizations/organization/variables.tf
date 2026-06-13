############################################################
# AWS Organization
############################################################

variable "aws_service_access_principals" {
  description = "(Optional) List of AWS service principal names for which you want to enable integration with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature_set set to ALL. For additional information, see the AWS Organizations User Guide."
  type        = list(string)
  default = [
    "account.amazonaws.com",
    "aws-artifact-account-sync.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "health.amazonaws.com",
    "sso.amazonaws.com",
  ]
}

variable "enabled_policy_types" {
  description = "(Optional) List of Organizations policy types to enable in the Organization Root. Organization must have feature_set set to ALL. For additional information about valid policy types (e.g., AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, and TAG_POLICY), see the AWS Organizations API Reference."
  type        = list(string)
  default     = null
}

variable "feature_set" {
  description = "(Optional) Specify 'ALL' (default) or 'CONSOLIDATED_BILLING'."
  type        = string
  default     = "ALL"
  validation {
    condition     = can(regex("ALL|CONSOLIDATED_BILLING", var.feature_set))
    error_message = "Value must be ALL or CONSOLIDATED_BILLING."
  }
}

variable "enabled_features" {
  description = "A list of IAM organization features which will be enabled. Valid values are RootCredentialsManagement and RootSessions."
  type        = list(string)
  default = [
    "RootCredentialsManagement",
    "RootSessions"
  ]
}

############################################################
# Identity Center Service Control Policy
############################################################

variable "enable_identity_center_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies sso:CreateInstance organization-wide so member accounts cannot create account-level IAM Identity Center instances. Defaults to true. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  default     = true
}

variable "identity_center_scp_name" {
  description = "(Optional) Name of the Identity Center deny SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  default     = "DenyMemberAccountIdentityCenter"
}

variable "identity_center_scp_description" {
  description = "(Optional) Description of the Identity Center deny SCP."
  type        = string
  default     = "Denies sso:CreateInstance org-wide so member accounts cannot create account-level IAM Identity Center instances."
}

variable "attach_identity_center_scp" {
  description = "(Optional) If true, attaches the Identity Center deny SCP to the targets in identity_center_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  default     = true
}

variable "identity_center_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Identity Center deny SCP to. When null and attach_identity_center_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

############################################################
# General Variables
############################################################

variable "enable_organization_backup" {
  description = "(Optional) If true, enables the organization backup policy. Defaults to false."
  type        = bool
  default     = false
}

variable "tags" {
  description = "(Optional) A map of tags to assign to the AWS Organization. Tags are key-value pairs that help organize and manage resources."
  type        = map(string)
  default = {
    terraform = "true"
  }
}
