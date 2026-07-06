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
  type        = "SERVICE_CONTROL_POLICY"
  tags        = var.tags
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
  type        = "SERVICE_CONTROL_POLICY"
  tags        = var.tags
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
