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
# Cloud Map HTTP Namespace
###########################

resource "aws_service_discovery_http_namespace" "this" {
  name        = var.name
  description = var.description
  tags        = merge(tomap({ Name = var.name }), var.tags)
}
