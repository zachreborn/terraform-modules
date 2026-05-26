terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
  }
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = var.client_id_list
  tags            = merge(var.tags, { Name = var.name })
  thumbprint_list = var.thumbprint_list
  url             = var.url
}
