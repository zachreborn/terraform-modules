terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "aws_security_group" "sg" {
  description = var.description
  name        = var.name
  tags        = merge(var.tags, ({ "Name" = format("%s", var.name) }))
  vpc_id      = var.vpc_id

  # A name change forces replacement; create_before_destroy avoids the
  # "DependencyViolation" delete-ordering problem for callers that reference
  # this group's id from other resources (e.g. VPC endpoints, rules attached
  # via aws_vpc_security_group_ingress_rule/egress_rule).
  lifecycle {
    create_before_destroy = true
  }
}
