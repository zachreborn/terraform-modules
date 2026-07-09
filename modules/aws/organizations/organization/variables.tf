############################################################
# AWS Organization
############################################################

variable "aws_service_access_principals" {
  description = "(Optional) List of AWS service principal names for which you want to enable trusted access (integration) with your organization. This is typically in the form of a URL, such as service-abbreviation.amazonaws.com. Organization must have feature_set set to ALL. The default list enables the centralized security services this module library integrates with (Security Hub, GuardDuty, Config, IAM Access Analyzer, and Inspector) so that their delegated-administrator modules do not create trusted-access drift. Note: once a service has a registered delegated administrator, removing its principal from this list will fail until the delegated administrator is deregistered. For additional information, see the AWS Organizations User Guide."
  type        = list(string)
  nullable    = false
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
  description = "(Optional) List of Organizations policy types to enable in the Organization Root. Organization must have feature_set set to ALL. Defaults to [\"SERVICE_CONTROL_POLICY\"] so the SCPs this module enables by default (Identity Center deny, Leave Organization deny, Root Access Key Creation deny) work out of the box without callers needing to set this explicitly. Override with a list that includes \"SERVICE_CONTROL_POLICY\" if you also need other policy types (e.g. [\"SERVICE_CONTROL_POLICY\", \"TAG_POLICY\"]), or set enable_identity_center_scp/enable_leave_organization_scp/enable_root_access_key_scp to false and this to [] if you don't want SCP support enabled at all. For additional information about valid policy types (e.g., AISERVICES_OPT_OUT_POLICY, BACKUP_POLICY, SERVICE_CONTROL_POLICY, and TAG_POLICY), see the AWS Organizations API Reference."
  type        = list(string)
  default     = ["SERVICE_CONTROL_POLICY"]
}

variable "feature_set" {
  description = "(Optional) Specify 'ALL' (default) or 'CONSOLIDATED_BILLING'."
  type        = string
  nullable    = false
  default     = "ALL"
  validation {
    condition     = can(regex("ALL|CONSOLIDATED_BILLING", var.feature_set))
    error_message = "Value must be ALL or CONSOLIDATED_BILLING."
  }
}

variable "enabled_features" {
  description = "A list of IAM organization features which will be enabled. Valid values are RootCredentialsManagement and RootSessions."
  type        = list(string)
  nullable    = false
  default = [
    "RootCredentialsManagement",
    "RootSessions"
  ]
}

############################################################
# Identity Center Service Control Policy
############################################################

variable "attach_identity_center_scp" {
  description = "(Optional) If true, attaches the Identity Center deny SCP to the targets in identity_center_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_identity_center_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies sso:CreateInstance organization-wide so member accounts cannot create account-level IAM Identity Center instances. Defaults to true. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  nullable    = false
  default     = true
}

variable "identity_center_scp_description" {
  description = "(Optional) Description of the Identity Center deny SCP."
  type        = string
  nullable    = false
  default     = "Denies sso:CreateInstance org-wide so member accounts cannot create account-level IAM Identity Center instances."
}

variable "identity_center_scp_name" {
  description = "(Optional) Name of the Identity Center deny SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  nullable    = false
  default     = "DenyMemberAccountIdentityCenter"
}

variable "identity_center_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Identity Center deny SCP to. When null and attach_identity_center_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

############################################################
# Region Restriction Service Control Policy
############################################################

variable "allowed_regions" {
  description = "(Required when enable_region_scp is true) List of AWS Regions where regional service actions remain allowed (e.g. [\"us-east-1\", \"us-west-2\"]). Used as the aws:RequestedRegion StringNotEquals value in the Region-deny SCP. Consider including us-east-1 because some global features route through it. Ignored when enable_region_scp is false."
  type        = list(string)
  nullable    = false
  default     = []
  validation {
    condition     = !var.enable_region_scp || length(var.allowed_regions) > 0
    error_message = "allowed_regions must contain at least one Region when enable_region_scp is true."
  }
}

variable "attach_region_scp" {
  description = "(Optional) If true, attaches the Region-deny SCP to the targets in region_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_region_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies regional AWS service actions outside the Regions listed in allowed_regions (global/non-regional services are exempted via NotAction). Opt-in: defaults to false so existing callers see no change until they enable it. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  nullable    = false
  default     = false
}

variable "region_scp_description" {
  description = "(Optional) Description of the Region-deny SCP."
  type        = string
  nullable    = false
  default     = "Denies regional AWS service actions outside the approved Regions in var.allowed_regions, exempting global services."
}

variable "region_scp_exempted_actions" {
  description = "(Optional) Additional actions merged into the built-in global-service NotAction list, for callers who depend on global services not covered out of the box (e.g. [\"pricingplanmanager:*\"]). Defaults to []."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "region_scp_exempted_principal_arns" {
  description = "(Optional) List of IAM principal ARNs (wildcards allowed, e.g. arn:aws:iam::*:role/BreakGlassRole) excluded from the Region deny via an ArnNotLike condition on aws:PrincipalARN, so break-glass / execution roles are not locked out. When empty, no ArnNotLike condition is added. Defaults to []."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "region_scp_name" {
  description = "(Optional) Name of the Region-deny SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  nullable    = false
  default     = "DenyAccessOutsideApprovedRegions"
}

variable "region_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Region-deny SCP to. When null and attach_region_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

############################################################
# Deny Leave Organization Service Control Policy
############################################################

variable "attach_leave_organization_scp" {
  description = "(Optional) If true, attaches the Deny Leave Organization SCP to the targets in leave_organization_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_leave_organization_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies organizations:LeaveOrganization organization-wide so member accounts cannot remove themselves from the organization. Defaults to true. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  nullable    = false
  default     = true
}

variable "leave_organization_scp_description" {
  description = "(Optional) Description of the Deny Leave Organization SCP."
  type        = string
  nullable    = false
  default     = "Denies organizations:LeaveOrganization org-wide so member accounts cannot remove themselves from the organization."
}

variable "leave_organization_scp_name" {
  description = "(Optional) Name of the Deny Leave Organization SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  nullable    = false
  default     = "DenyLeaveOrganization"
}

variable "leave_organization_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Deny Leave Organization SCP to. When null and attach_leave_organization_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

############################################################
# Deny Root Access Key Creation Service Control Policy
############################################################

variable "attach_root_access_key_scp" {
  description = "(Optional) If true, attaches the Deny Root Access Key Creation SCP to the targets in root_access_key_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_root_access_key_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies iam:CreateAccessKey for the account root user organization-wide, preventing creation of long-lived root user access keys in member accounts. Defaults to true. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  nullable    = false
  default     = true
}

variable "root_access_key_scp_description" {
  description = "(Optional) Description of the Deny Root Access Key Creation SCP."
  type        = string
  nullable    = false
  default     = "Denies iam:CreateAccessKey for the account root user org-wide so member accounts cannot create long-lived root user access keys."
}

variable "root_access_key_scp_name" {
  description = "(Optional) Name of the Deny Root Access Key Creation SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  nullable    = false
  default     = "DenyRootAccessKeyCreation"
}

variable "root_access_key_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Deny Root Access Key Creation SCP to. When null and attach_root_access_key_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

############################################################
# Deny Security Service Tampering Service Control Policy
############################################################

variable "attach_security_services_scp" {
  description = "(Optional) If true, attaches the Deny Security Service Tampering SCP to the targets in security_services_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_security_services_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies actions that stop, disable, or delete CloudTrail, AWS Config, GuardDuty, and Security Hub in member accounts. Opt-in: defaults to false so existing callers see no change until they enable it, and so delegated-administrator/audit roles can be exempted first via security_services_scp_exempted_principal_arns. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  nullable    = false
  default     = false
}

variable "security_services_scp_description" {
  description = "(Optional) Description of the Deny Security Service Tampering SCP."
  type        = string
  nullable    = false
  default     = "Denies actions that stop, disable, or delete CloudTrail, AWS Config, GuardDuty, and Security Hub in member accounts."
}

variable "security_services_scp_exempted_principal_arns" {
  description = "(Optional) List of IAM principal ARNs (wildcards allowed, e.g. arn:aws:iam::*:role/DelegatedSecurityAdminRole) excluded from the deny via an ArnNotLike condition on aws:PrincipalARN, so delegated-administrator, break-glass, or automation roles that legitimately manage these security services are not locked out. When empty, no ArnNotLike condition is added. Defaults to []."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "security_services_scp_name" {
  description = "(Optional) Name of the Deny Security Service Tampering SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  nullable    = false
  default     = "DenySecurityServiceTampering"
}

variable "security_services_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Deny Security Service Tampering SCP to. When null and attach_security_services_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

############################################################
# Deny Root User Actions Service Control Policy
############################################################

variable "attach_root_actions_scp" {
  description = "(Optional) If true, attaches the Deny Root User Actions SCP to the targets in root_actions_scp_target_ids (defaulting to the organization root). When false, the policy is created but not attached. Defaults to true."
  type        = bool
  nullable    = false
  default     = true
}

variable "enable_root_actions_scp" {
  description = "(Optional) If true, creates a Service Control Policy (SCP) which denies all actions taken by the account root user in member accounts, except the actions in root_actions_scp_exempted_actions. Opt-in: defaults to false because an overly narrow exemption list can lock out legitimate root-only recovery flows; test in a non-production OU before wider rollout. Requires SERVICE_CONTROL_POLICY in enabled_policy_types."
  type        = bool
  nullable    = false
  default     = false
}

variable "root_actions_scp_description" {
  description = "(Optional) Description of the Deny Root User Actions SCP."
  type        = string
  nullable    = false
  default     = "Denies all actions taken by the account root user in member accounts, except the built-in and caller-supplied exempted actions."
}

variable "root_actions_scp_exempted_actions" {
  description = "(Optional) Additional actions merged into the built-in NotAction allowlist so legitimate root-only actions are not denied. The built-in list already covers the AWS-documented tasks that require root user credentials and are not exempted via the aws:AssumedRoot condition (S3 bucket-policy and MFA Delete recovery, SQS queue-policy recovery, billing/Support-plan changes, and EC2 Reserved Instance Marketplace seller registration). It deliberately does NOT exempt broad iam:* actions for the 'restore IAM user permissions if locked out' scenario -- add iam actions here yourself if you want that break-glass path. Defaults to []."
  type        = list(string)
  nullable    = false
  default     = []
}

variable "root_actions_scp_name" {
  description = "(Optional) Name of the Deny Root User Actions SCP. Used as the name of the aws_organizations_policy created via the policy module."
  type        = string
  nullable    = false
  default     = "DenyRootUserActions"
}

variable "root_actions_scp_target_ids" {
  description = "(Optional) List of organization root, OU, or account IDs to attach the Deny Root User Actions SCP to. When null and attach_root_actions_scp is true, the SCP is attached to the organization root. Defaults to null."
  type        = list(string)
  default     = null
}

############################################################
# General Variables
############################################################

variable "enable_organization_backup" {
  description = "(Optional) If true, enables the organization backup policy. Defaults to false."
  type        = bool
  nullable    = false
  default     = false
}

variable "tags" {
  description = "(Optional) A map of tags to assign to the AWS Organization. Tags are key-value pairs that help organize and manage resources."
  type        = map(string)
  nullable    = false
  default = {
    terraform = "true"
  }
}
