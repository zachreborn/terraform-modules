terraform {
  required_version = ">= 1.0.0"
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

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["workspaces.amazonaws.com"]
    }
  }
}

###########################
# Locals
###########################

locals {
  # AmazonWorkSpacesServiceAccess is always required for the WorkSpaces service to manage ENIs on behalf of
  # directories/desktops. AmazonWorkSpacesSelfServiceAccess is only needed when self-service actions
  # (rebuild, restart, change compute type, etc.) are delegated to this role, so it is opt-in.
  policy_arns = concat(
    ["arn:aws:iam::aws:policy/AmazonWorkSpacesServiceAccess"],
    var.enable_self_service_access ? ["arn:aws:iam::aws:policy/AmazonWorkSpacesSelfServiceAccess"] : []
  )
}

###########################
# workspaces_DefaultRole
###########################

module "role" {
  source = "../../iam/role"

  name               = var.name
  description        = "Service-linked role used by Amazon WorkSpaces to manage Elastic Network Interfaces and (optionally) self-service actions on behalf of directory users."
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  policy_arns        = local.policy_arns
  tags               = var.tags
}
