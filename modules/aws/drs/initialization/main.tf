###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0: var.additional_policy_arns and the role map handling below rely on
  # optional() object attributes, introduced in Terraform 1.3 / OpenTofu 1.6.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Data Sources
###########################

data "aws_caller_identity" "this" {}

data "aws_partition" "this" {}

###########################
# Locals
###########################

locals {
  account_id     = data.aws_caller_identity.this.account_id
  policy_prefix  = "arn:${data.aws_partition.this.partition}:iam::aws:policy"
  service_prefix = "arn:${data.aws_partition.this.partition}:iam::aws:policy/service-role"

  # Roles that Elastic Disaster Recovery itself assumes. The sts:SetSourceIdentity
  # action plus the sts:SourceIdentity and aws:SourceAccount conditions are the
  # confused-deputy guard AWS documents for these two roles -- do not drop them.
  # See https://docs.aws.amazon.com/drs/latest/userguide/getting-started-initializing.html
  drs_assume_role_policies = {
    for role_name, source_identity_prefix in {
      AWSElasticDisasterRecoveryAgentRole    = "s-*"
      AWSElasticDisasterRecoveryFailbackRole = "i-*"
      } : role_name => jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "drs.amazonaws.com"
            }
            Action = [
              "sts:AssumeRole",
              "sts:SetSourceIdentity",
            ]
            Condition = {
              StringLike = {
                "sts:SourceIdentity" = source_identity_prefix
                "aws:SourceAccount"  = local.account_id
              }
            }
          },
        ]
    })
  }

  # Roles assumed by the EC2 instances Elastic Disaster Recovery launches
  # (replication servers, conversion servers, and recovery instances).
  ec2_assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      },
    ]
  })

  # The six IAM roles DRS service initialization creates, with the managed
  # policy pairings documented in the Elastic Disaster Recovery user guide. The
  # four EC2-assumed roles additionally need an instance profile, which the
  # console-driven initialization creates for you.
  roles = {
    AWSElasticDisasterRecoveryAgentRole = {
      assume_role_policy      = local.drs_assume_role_policies["AWSElasticDisasterRecoveryAgentRole"]
      create_instance_profile = false
      description             = "Assumed by AWS Elastic Disaster Recovery on behalf of the AWS Replication Agent running on a source server."
      policy_arns             = ["${local.service_prefix}/AWSElasticDisasterRecoveryAgentPolicy"]
    }

    AWSElasticDisasterRecoveryFailbackRole = {
      assume_role_policy      = local.drs_assume_role_policies["AWSElasticDisasterRecoveryFailbackRole"]
      create_instance_profile = false
      description             = "Assumed by AWS Elastic Disaster Recovery during failback from a recovery instance to its origin."
      policy_arns             = ["${local.service_prefix}/AWSElasticDisasterRecoveryFailbackPolicy"]
    }

    AWSElasticDisasterRecoveryConversionServerRole = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      description             = "Assumed by the AWS Elastic Disaster Recovery conversion servers launched in the staging area."
      policy_arns             = ["${local.service_prefix}/AWSElasticDisasterRecoveryConversionServerPolicy"]
    }

    AWSElasticDisasterRecoveryRecoveryInstanceRole = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      description             = "Assumed by AWS Elastic Disaster Recovery recovery instances."
      policy_arns             = ["${local.service_prefix}/AWSElasticDisasterRecoveryRecoveryInstancePolicy"]
    }

    AWSElasticDisasterRecoveryRecoveryInstanceWithLaunchActionsRole = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      description             = "Assumed by AWS Elastic Disaster Recovery recovery instances that run post-launch actions via AWS Systems Manager."
      policy_arns = [
        "${local.service_prefix}/AWSElasticDisasterRecoveryRecoveryInstancePolicy",
        "${local.policy_prefix}/AmazonSSMManagedInstanceCore",
      ]
    }

    AWSElasticDisasterRecoveryReplicationServerRole = {
      assume_role_policy      = local.ec2_assume_role_policy
      create_instance_profile = true
      description             = "Assumed by the AWS Elastic Disaster Recovery replication servers launched in the staging area."
      policy_arns             = ["${local.service_prefix}/AWSElasticDisasterRecoveryReplicationServerPolicy"]
    }
  }

  created_roles = var.create_service_roles ? local.roles : {}

  # Merge each role's documented managed policies with any caller-supplied
  # additions, computed as its own local (rather than inline in the module
  # block below) so the effective set is assertable from tests, since the
  # shared modules/aws/iam/role module does not output policy_arns.
  effective_policy_arns = {
    for role_name, role in local.created_roles : role_name => concat(role.policy_arns, lookup(var.additional_policy_arns, role_name, []))
  }

  instance_profile_roles = {
    for role_name, role in local.created_roles : role_name => role
    if role.create_instance_profile
  }
}

###########################
# Service Roles (composition)
###########################

module "role" {
  source = "../../iam/role"

  for_each = local.created_roles

  assume_role_policy   = each.value.assume_role_policy
  description          = each.value.description
  max_session_duration = var.max_session_duration
  name                 = each.key
  path                 = var.path
  permissions_boundary = var.permissions_boundary
  policy_arns          = local.effective_policy_arns[each.key]
  tags                 = merge(tomap({ Name = each.key }), var.tags)
}

###########################
# Instance Profiles
###########################

resource "aws_iam_instance_profile" "this" {
  for_each = local.instance_profile_roles

  name = each.key
  path = var.path
  role = module.role[each.key].name
  tags = merge(tomap({ Name = each.key }), var.tags)
}

###########################
# Service-Linked Role
###########################

resource "aws_iam_service_linked_role" "this" {
  count = var.create_service_linked_role ? 1 : 0

  aws_service_name = "drs.amazonaws.com"
  description      = var.service_linked_role_description
  tags             = merge(tomap({ Name = "AWSServiceRoleForElasticDisasterRecovery" }), var.tags)
}
