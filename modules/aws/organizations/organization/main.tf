terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.78.0"
    }
  }
}

###########################################################
# AWS Organization
###########################################################

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = var.aws_service_access_principals
  enabled_policy_types          = var.enabled_policy_types
  feature_set                   = var.feature_set

  lifecycle {
    prevent_destroy = true
  }
}

###########################################################
# Centralized Root Management
###########################################################
module "centralized_root" {
  source = "../../iam/organizations_features"

  enabled_features = var.enabled_features
}

###########################################################
# Centralized AWS Backup Management
###########################################################

module "centralized_backup" {
  source = "../policy"

  for_each = var.enable_organization_backup ? { "backup_policy" = "true" } : {}

  content     = file("${path.module}/policies/enable_backup_policy.json")
  description = "Centralized AWS Backup Policy for managing backup plans across the organization."
  name        = "Root"
  type        = "BACKUP_POLICY"
  tags        = var.tags
}

###########################################################
# Identity Center Service Control Policy
###########################################################

locals {
  # Targets the SCP is attached to. Defaults to the organization root when no
  # explicit targets are supplied and attachment is enabled.
  identity_center_scp_attachment_target_ids = (
    var.enable_identity_center_scp && var.attach_identity_center_scp
    ? (
      var.identity_center_scp_target_ids != null
      ? var.identity_center_scp_target_ids
      : [aws_organizations_organization.org.roots[0].id]
    )
    : []
  )
}

module "identity_center_scp" {
  source = "../policy"

  for_each = var.enable_identity_center_scp ? { "identity_center_scp" = "true" } : {}

  content     = file("${path.module}/policies/deny_identity_center_instance_scp.json")
  description = var.identity_center_scp_description
  name        = var.identity_center_scp_name
  tags        = var.tags
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "identity_center_scp" {
  for_each = toset(local.identity_center_scp_attachment_target_ids)

  policy_id = module.identity_center_scp["identity_center_scp"].id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = !var.enable_identity_center_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")
      error_message = "enable_identity_center_scp is true but \"SERVICE_CONTROL_POLICY\" is not present in enabled_policy_types. Add \"SERVICE_CONTROL_POLICY\" to enabled_policy_types so the Identity Center SCP can be created and attached."
    }
  }
}

###########################################################
# Region Restriction Service Control Policy
###########################################################

locals {
  # NotAction list for the region-deny SCP — merges the built-in global/non-regional
  # service list (modeled on CT.MULTISERVICE.PV.1 / GRREGIONDENY) with any
  # caller-supplied additional exemptions.
  region_scp_not_actions = distinct(concat([
    "a4b:*",
    "access-analyzer:*",
    "account:*",
    "acm:*",
    "activate:*",
    "artifact:*",
    "aws-marketplace-management:*",
    "aws-marketplace:*",
    "aws-portal:*",
    "billing:*",
    "billingconductor:*",
    "budgets:*",
    "ce:*",
    "chatbot:*",
    "chime:*",
    "cloudfront:*",
    "cloudtrail:LookupEvents",
    "compute-optimizer:*",
    "config:*",
    "consoleapp:*",
    "consolidatedbilling:*",
    "cur:*",
    "datapipeline:GetAccountLimits",
    "devicefarm:*",
    "directconnect:*",
    "ec2:DescribeRegions",
    "ec2:DescribeTransitGateways",
    "ec2:DescribeVpnGateways",
    "ecr-public:*",
    "fms:*",
    "freetier:*",
    "globalaccelerator:*",
    "health:*",
    "iam:*",
    "importexport:*",
    "invoicing:*",
    "iq:*",
    "kms:*",
    "license-manager:ListReceivedLicenses",
    "lightsail:Get*",
    "mobileanalytics:*",
    "networkmanager:*",
    "notifications-contacts:*",
    "notifications:*",
    "organizations:*",
    "payments:*",
    "pricing:*",
    "quicksight:DescribeAccountSubscription",
    "resource-explorer-2:*",
    "route53-recovery-cluster:*",
    "route53-recovery-control-config:*",
    "route53-recovery-readiness:*",
    "route53:*",
    "route53domains:*",
    "s3:CreateMultiRegionAccessPoint",
    "s3:DeleteMultiRegionAccessPoint",
    "s3:DescribeMultiRegionAccessPointOperation",
    "s3:GetAccountPublicAccessBlock",
    "s3:GetBucketLocation",
    "s3:GetBucketPolicyStatus",
    "s3:GetBucketPublicAccessBlock",
    "s3:GetMultiRegionAccessPoint",
    "s3:GetMultiRegionAccessPointPolicy",
    "s3:GetMultiRegionAccessPointPolicyStatus",
    "s3:GetStorageLensConfiguration",
    "s3:GetStorageLensDashboard",
    "s3:ListAllMyBuckets",
    "s3:ListMultiRegionAccessPoints",
    "s3:ListStorageLensConfigurations",
    "s3:PutAccountPublicAccessBlock",
    "s3:PutMultiRegionAccessPointPolicy",
    "savingsplans:*",
    "shield:*",
    "sso:*",
    "sts:*",
    "support:*",
    "supportapp:*",
    "supportplans:*",
    "sustainability:*",
    "tag:GetResources",
    "tax:*",
    "trustedadvisor:*",
    "vendor-insights:ListEntitledSecurityProfiles",
    "waf-regional:*",
    "waf:*",
    "wafv2:*",
  ], var.region_scp_exempted_actions))

  # Condition block for the Region-deny SCP. The StringNotEquals key denies any
  # regional action whose aws:RequestedRegion is not in allowed_regions. The
  # ArnNotLike key is added only when exempted principal ARNs are supplied, so
  # break-glass / execution roles are not locked out. Keys within a single
  # Condition are AND-ed.
  region_scp_condition = merge(
    {
      StringNotEquals = {
        "aws:RequestedRegion" = var.allowed_regions
      }
    },
    length(var.region_scp_exempted_principal_arns) > 0 ? {
      ArnNotLike = {
        "aws:PrincipalARN" = var.region_scp_exempted_principal_arns
      }
    } : {}
  )

  # Complete policy document generated entirely in HCL via jsonencode() —
  # no template file required. jsonencode() always produces syntactically valid
  # JSON, so JSON linters pass without issue.
  region_scp_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyAccessOutsideApprovedRegions"
        Effect    = "Deny"
        NotAction = local.region_scp_not_actions
        Resource  = "*"
        Condition = local.region_scp_condition
      }
    ]
  })

  # Targets the SCP is attached to. Defaults to the organization root when no
  # explicit targets are supplied and attachment is enabled.
  region_scp_attachment_target_ids = (
    var.enable_region_scp && var.attach_region_scp
    ? (
      var.region_scp_target_ids != null
      ? var.region_scp_target_ids
      : [aws_organizations_organization.org.roots[0].id]
    )
    : []
  )
}

module "region_scp" {
  source = "../policy"

  for_each = var.enable_region_scp ? { "region_scp" = "true" } : {}

  content     = local.region_scp_content
  description = var.region_scp_description
  name        = var.region_scp_name
  tags        = var.tags
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "region_scp" {
  for_each = toset(local.region_scp_attachment_target_ids)

  policy_id = module.region_scp["region_scp"].id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = !var.enable_region_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")
      error_message = "enable_region_scp is true but \"SERVICE_CONTROL_POLICY\" is not present in enabled_policy_types. Add \"SERVICE_CONTROL_POLICY\" to enabled_policy_types so the Region-deny SCP can be created and attached."
    }
  }
}

###########################################################
# Deny Leave Organization Service Control Policy
###########################################################

locals {
  # Targets the SCP is attached to. Defaults to the organization root when no
  # explicit targets are supplied and attachment is enabled.
  leave_organization_scp_attachment_target_ids = (
    var.enable_leave_organization_scp && var.attach_leave_organization_scp
    ? (
      var.leave_organization_scp_target_ids != null
      ? var.leave_organization_scp_target_ids
      : [aws_organizations_organization.org.roots[0].id]
    )
    : []
  )
}

module "leave_organization_scp" {
  source = "../policy"

  for_each = var.enable_leave_organization_scp ? { "leave_organization_scp" = "true" } : {}

  content     = file("${path.module}/policies/deny_leave_organization_scp.json")
  description = var.leave_organization_scp_description
  name        = var.leave_organization_scp_name
  tags        = var.tags
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "leave_organization_scp" {
  for_each = toset(local.leave_organization_scp_attachment_target_ids)

  policy_id = module.leave_organization_scp["leave_organization_scp"].id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = !var.enable_leave_organization_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")
      error_message = "enable_leave_organization_scp is true but \"SERVICE_CONTROL_POLICY\" is not present in enabled_policy_types. Add \"SERVICE_CONTROL_POLICY\" to enabled_policy_types so the Deny Leave Organization SCP can be created and attached."
    }
  }
}

###########################################################
# Deny Root Access Key Creation Service Control Policy
###########################################################

locals {
  # Targets the SCP is attached to. Defaults to the organization root when no
  # explicit targets are supplied and attachment is enabled.
  root_access_key_scp_attachment_target_ids = (
    var.enable_root_access_key_scp && var.attach_root_access_key_scp
    ? (
      var.root_access_key_scp_target_ids != null
      ? var.root_access_key_scp_target_ids
      : [aws_organizations_organization.org.roots[0].id]
    )
    : []
  )
}

module "root_access_key_scp" {
  source = "../policy"

  for_each = var.enable_root_access_key_scp ? { "root_access_key_scp" = "true" } : {}

  content     = file("${path.module}/policies/deny_root_access_key_creation_scp.json")
  description = var.root_access_key_scp_description
  name        = var.root_access_key_scp_name
  tags        = var.tags
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "root_access_key_scp" {
  for_each = toset(local.root_access_key_scp_attachment_target_ids)

  policy_id = module.root_access_key_scp["root_access_key_scp"].id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = !var.enable_root_access_key_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")
      error_message = "enable_root_access_key_scp is true but \"SERVICE_CONTROL_POLICY\" is not present in enabled_policy_types. Add \"SERVICE_CONTROL_POLICY\" to enabled_policy_types so the Deny Root Access Key Creation SCP can be created and attached."
    }
  }
}

###########################################################
# Deny Security Service Tampering Service Control Policy
###########################################################

locals {
  # Actions that stop, disable, or delete the centralized security services this module already
  # integrates via aws_service_access_principals: CloudTrail, AWS Config, GuardDuty, and Security Hub.
  security_services_scp_denied_actions = [
    "cloudtrail:DeleteTrail",
    "cloudtrail:PutEventSelectors",
    "cloudtrail:StopLogging",
    "cloudtrail:UpdateTrail",
    "config:DeleteConfigurationRecorder",
    "config:DeleteDeliveryChannel",
    "config:StopConfigurationRecorder",
    "guardduty:DeleteDetector",
    "guardduty:DisassociateFromAdministratorAccount",
    "guardduty:DisassociateFromMasterAccount",
    "guardduty:StopMonitoringMembers",
    "guardduty:UpdateDetector",
    "securityhub:DeleteMembers",
    "securityhub:DisableSecurityHub",
    "securityhub:DisassociateFromAdministratorAccount",
    "securityhub:DisassociateFromMasterAccount",
    "securityhub:DisassociateMembers",
  ]

  # Condition block for the security-services deny SCP. The ArnNotLike key is added only when
  # exempted principal ARNs are supplied, so delegated-administrator / break-glass roles are not
  # locked out of managing these services.
  security_services_scp_condition = length(var.security_services_scp_exempted_principal_arns) > 0 ? {
    ArnNotLike = {
      "aws:PrincipalARN" = var.security_services_scp_exempted_principal_arns
    }
  } : {}

  security_services_scp_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      merge(
        {
          Sid      = "DenySecurityServiceTampering"
          Effect   = "Deny"
          Action   = local.security_services_scp_denied_actions
          Resource = "*"
        },
        length(local.security_services_scp_condition) > 0 ? { Condition = local.security_services_scp_condition } : {}
      )
    ]
  })

  # Targets the SCP is attached to. Defaults to the organization root when no
  # explicit targets are supplied and attachment is enabled.
  security_services_scp_attachment_target_ids = (
    var.enable_security_services_scp && var.attach_security_services_scp
    ? (
      var.security_services_scp_target_ids != null
      ? var.security_services_scp_target_ids
      : [aws_organizations_organization.org.roots[0].id]
    )
    : []
  )
}

module "security_services_scp" {
  source = "../policy"

  for_each = var.enable_security_services_scp ? { "security_services_scp" = "true" } : {}

  content     = local.security_services_scp_content
  description = var.security_services_scp_description
  name        = var.security_services_scp_name
  tags        = var.tags
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "security_services_scp" {
  for_each = toset(local.security_services_scp_attachment_target_ids)

  policy_id = module.security_services_scp["security_services_scp"].id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = !var.enable_security_services_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")
      error_message = "enable_security_services_scp is true but \"SERVICE_CONTROL_POLICY\" is not present in enabled_policy_types. Add \"SERVICE_CONTROL_POLICY\" to enabled_policy_types so the Deny Security Service Tampering SCP can be created and attached."
    }
  }
}

###########################################################
# Deny Root User Actions Service Control Policy
###########################################################

locals {
  # Built-in NotAction allowlist covering AWS-documented tasks that require root user credentials
  # (https://docs.aws.amazon.com/IAM/latest/UserGuide/root-user-tasks.html) and that are NOT already
  # covered by the aws:AssumedRoot exemption below (i.e. tasks a member account's own root user must
  # perform directly, rather than via a management-account-initiated centralized root session):
  #   - Amazon S3: recovering a bucket policy that denies all principals, and configuring MFA Delete.
  #   - Amazon SQS: recovering a queue resource policy that denies all principals.
  #   - Billing/Support: activating IAM access to Billing and Cost Management, changing the Support
  #     plan, and other billing tasks limited to root (aws-portal, billing, freetier, invoicing,
  #     payments, tax namespaces).
  #   - Amazon EC2: registering as a seller in the Reserved Instance Marketplace.
  # Deliberately NOT exempted: broad iam:* actions for "restore IAM user permissions if locked out".
  # Exempting that would defeat the purpose of this SCP; add it to root_actions_scp_exempted_actions
  # yourself if you want that break-glass path and accept the reduced guarantee.
  root_actions_scp_not_actions = distinct(concat([
    "aws-portal:*",
    "billing:*",
    "ec2:CancelReservedInstancesListing",
    "ec2:CreateReservedInstancesListing",
    "freetier:*",
    "invoicing:*",
    "payments:*",
    "s3:DeleteBucketPolicy",
    "s3:GetBucketPolicy",
    "s3:PutBucketPolicy",
    "s3:PutBucketVersioning",
    "sqs:GetQueueAttributes",
    "sqs:SetQueueAttributes",
    "tax:*",
  ], var.root_actions_scp_exempted_actions))

  root_actions_scp_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyRootUserActions"
        Effect    = "Deny"
        NotAction = local.root_actions_scp_not_actions
        Resource  = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = ["arn:aws:iam::*:root"]
          }
          # Exempts short-lived, task-scoped root sessions created via the centralized root access
          # feature (sts:AssumeRoot from the management account or a delegated administrator), which
          # assume the member account's root identity but are already scoped by their own AWS managed
          # task policy and are always initiated from and audited by the management account. Without
          # this, centralized root credential management and S3/SQS policy-unlock sessions would be
          # blocked. See https://docs.aws.amazon.com/IAM/latest/UserGuide/id_root-user-privileged-task.html.
          BoolIfExists = {
            "aws:AssumedRoot" = "false"
          }
        }
      }
    ]
  })

  # Targets the SCP is attached to. Defaults to the organization root when no
  # explicit targets are supplied and attachment is enabled.
  root_actions_scp_attachment_target_ids = (
    var.enable_root_actions_scp && var.attach_root_actions_scp
    ? (
      var.root_actions_scp_target_ids != null
      ? var.root_actions_scp_target_ids
      : [aws_organizations_organization.org.roots[0].id]
    )
    : []
  )
}

module "root_actions_scp" {
  source = "../policy"

  for_each = var.enable_root_actions_scp ? { "root_actions_scp" = "true" } : {}

  content     = local.root_actions_scp_content
  description = var.root_actions_scp_description
  name        = var.root_actions_scp_name
  tags        = var.tags
  type        = "SERVICE_CONTROL_POLICY"
}

resource "aws_organizations_policy_attachment" "root_actions_scp" {
  for_each = toset(local.root_actions_scp_attachment_target_ids)

  policy_id = module.root_actions_scp["root_actions_scp"].id
  target_id = each.value

  lifecycle {
    precondition {
      condition     = !var.enable_root_actions_scp || contains(coalesce(var.enabled_policy_types, []), "SERVICE_CONTROL_POLICY")
      error_message = "enable_root_actions_scp is true but \"SERVICE_CONTROL_POLICY\" is not present in enabled_policy_types. Add \"SERVICE_CONTROL_POLICY\" to enabled_policy_types so the Deny Root User Actions SCP can be created and attached."
    }
  }
}
