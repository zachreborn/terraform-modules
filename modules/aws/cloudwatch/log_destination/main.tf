terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###################################
# Cloudwatch Log Destination
###################################

resource "aws_cloudwatch_log_destination" "this" {
  name       = var.destination_name
  role_arn   = var.destination_role_arn
  target_arn = var.destination_target_arn
  tags       = merge(tomap({ Name = var.destination_name }), var.tags)
}

###################################
# Cloudwatch Log Destination Policy
###################################

resource "aws_cloudwatch_log_destination_policy" "this" {
  count            = var.destination_policy_access_policy != null ? 1 : 0
  destination_name = aws_cloudwatch_log_destination.this.name
  access_policy    = var.destination_policy_access_policy
  force_update     = var.destination_policy_force_update
}
