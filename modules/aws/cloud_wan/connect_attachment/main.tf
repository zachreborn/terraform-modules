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
# Connect Attachments
###########################
resource "aws_networkmanager_connect_attachment" "this" {
  for_each                = var.connect_attachments
  core_network_id         = var.core_network_id
  transport_attachment_id = each.value.transport_attachment_id
  edge_location           = each.value.edge_location

  options {
    protocol = each.value.protocol
  }

  tags = merge(tomap({ Name = each.key }), var.tags)
}
