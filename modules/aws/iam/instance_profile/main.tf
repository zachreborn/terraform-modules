###########################
# Provider Configuration
###########################
terraform {
  # Resource preconditions were introduced in Terraform 1.2.0.
  required_version = ">= 1.2.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # All instance-profile arguments and outputs predate the repository baseline.
      version = ">= 6.0.0"
    }
  }
}

###########################
# Instance Profile
###########################
resource "aws_iam_instance_profile" "this" {
  name        = var.name_prefix == null ? var.name : null
  name_prefix = var.name_prefix != null ? var.name_prefix : null
  path        = var.path
  role        = var.role
  tags        = merge(var.name != null ? tomap({ Name = var.name }) : {}, var.tags)

  lifecycle {
    precondition {
      condition     = (var.name != null) != (var.name_prefix != null)
      error_message = "Exactly one of name or name_prefix must be set; one, and only one, is required."
    }
  }
}
