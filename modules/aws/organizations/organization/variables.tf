############################################################
# AWS Organization
############################################################

variable "aws_service_access_principals" {
  description = "(Optional) List of AWS service principal names for which you want to enable trusted access (integration) with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature_set set to ALL. The default list enables the centralized security services this module library integrates with (Security Hub, GuardDuty, Config, IAM Access Analyzer, and Inspector) so that their delegated-administrator modules do not create trusted-access drift. Note: once a service has a registered delegated administrator, removing its principal from this list will fail until the delegated administrator is deregistered. For additional information, see the AWS Organizations User Guide."
  type        = list(string)
  default = [
    "access-analyzer.amazonaws.com",
    "account.amazonaws.com",
    "aws-artifact-account-sync.amazonaws.com",
    "backup.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "guardduty.amazonaws.com",
    "health.amazonaws.com",
    "inspector2.amazonaws.com",
    "securityhub.amazonaws.com",
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
# Region Restriction Service Control Policy
############################################################

variable "enable_region_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies regional AWS service actions outside the Regions listed in allowed_regions (global/non-regional services are exempted via NotAction). Opt-in: defaults to false so existing callers see no change until they enable it. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  default     = false
}

variable "allowed_regions" {
  description = "(Required when enable_region_scp is true) List of AWS Regions where regional service actions remain allowed (e.g. [\"us-east-1\", \"us-west-2\"]). Used as the aws:RequestedRegion StringNotEquals value in the Region-deny SCP. Consider including us-east-1 because some global features route through it. Ignored when enable_region_scp is false."
  type        = list(string)
  default     = []
  validation {
    condition     = !var.enable_region_scp || length(var.allowed_regions) > 0
    error_message = "allowed_regions must contain at least one Region when enable_region_scp is true."
  }
}

variable "region_scp_name" {
  description = "(Optional) Name of the Region-deny SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  default     = "DenyAccessOutsideApprovedRegions"
}

variable "region_scp_description" {
  description = "(Optional) Description of the Region-deny SCP."
  type        = string
  default     = "Denies regional AWS service actions outside the approved Regions in var.allowed_regions, exempting global services."
}

variable "attach_region_scp" {
  description = "(Optional) If true, attaches the Region-deny SCP to the targets in region_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  default     = true
}

variable "region_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Region-deny SCP to. When null and attach_region_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

variable "region_scp_exempted_principal_arns" {
  description = "(Optional) List of IAM principal ARNs (wildcards allowed, e.g. arn:aws:iam::*:role/BreakGlassRole) excluded from the Region deny via an ArnNotLike condition on aws:PrincipalARN, so break-glass / execution roles are not locked out. When empty, no ArnNotLike condition is added. Defaults to []."
  type        = list(string)
  default     = []
}

variable "region_scp_exempted_actions" {
  description = "(Optional) Additional actions merged into the built-in global-service NotAction list, for callers who depend on global services not covered out of the box (e.g. [\"pricingplanmanager:*\"]). Defaults to []."
  type        = list(string)
  default     = []
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
