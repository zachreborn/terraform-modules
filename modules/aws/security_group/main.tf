terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

# NOTE: create_before_destroy is intentionally NOT set here. This module
# only supports a static, caller-supplied `name` (no name_prefix option), and
# a name is not the only ForceNew argument on aws_security_group -- changing
# `description` also forces replacement. With create_before_destroy, the
# replacement resource would attempt to create using the same still-in-use
# name before the old one is destroyed, and AWS rejects that as a duplicate
# group. Callers that need zero-downtime replacement should give this module
# a name that they version themselves (e.g. include a suffix they control).
resource "aws_security_group" "sg" {
  description = var.description
  name        = var.name
  tags        = merge(var.tags, ({ "Name" = format("%s", var.name) }))
  vpc_id      = var.vpc_id
}
