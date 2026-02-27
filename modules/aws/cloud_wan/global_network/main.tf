###########################
# Provider Configuration
###########################
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
# Global Network
###########################
resource "aws_networkmanager_global_network" "this" {
  description = var.description
  tags        = merge(tomap({ Name = var.name }), var.tags)
}
