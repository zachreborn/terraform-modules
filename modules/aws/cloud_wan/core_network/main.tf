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
# Core Network
###########################
resource "aws_networkmanager_core_network" "this" {
  description         = var.description
  global_network_id   = var.global_network_id
  base_policy_regions = var.base_policy_regions
  create_base_policy  = var.create_base_policy
  tags                = merge(tomap({ Name = var.name }), var.tags)
}

###########################
# Core Network Policy Attachment
###########################
resource "aws_networkmanager_core_network_policy_attachment" "this" {
  count           = var.policy_document != null ? 1 : 0
  core_network_id = aws_networkmanager_core_network.this.id
  policy_document = var.policy_document
}
