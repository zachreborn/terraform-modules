###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0: managed_scaling's object type uses optional() attributes
  # (stable since Terraform 1.3 / OpenTofu 1.6).
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# ECS Capacity Provider
###########################

resource "aws_ecs_capacity_provider" "this" {
  name = var.name

  auto_scaling_group_provider {
    auto_scaling_group_arn         = var.auto_scaling_group_arn
    managed_draining               = var.managed_draining
    managed_termination_protection = var.managed_termination_protection

    managed_scaling {
      status                    = var.managed_scaling.status
      target_capacity           = var.managed_scaling.target_capacity
      minimum_scaling_step_size = var.managed_scaling.minimum_scaling_step_size
      maximum_scaling_step_size = var.managed_scaling.maximum_scaling_step_size
      instance_warmup_period    = var.managed_scaling.instance_warmup_period
    }
  }

  tags = merge(tomap({ Name = var.name }), var.tags)
}
