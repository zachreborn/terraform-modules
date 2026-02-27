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

  dynamic "proposed_segment_change" {
    for_each = each.value.proposed_segment_change != null ? [each.value.proposed_segment_change] : []
    content {
      attachment_policy_rule_number = proposed_segment_change.value.attachment_policy_rule_number
      segment_name                  = proposed_segment_change.value.segment_name
      tags                          = proposed_segment_change.value.tags
    }
  }

  dynamic "proposed_network_function_group_change" {
    for_each = each.value.proposed_network_function_group_change != null ? [each.value.proposed_network_function_group_change] : []
    content {
      attachment_policy_rule_number = proposed_network_function_group_change.value.attachment_policy_rule_number
      network_function_group_name   = proposed_network_function_group_change.value.network_function_group_name
      tags                          = proposed_network_function_group_change.value.tags
    }
  }
}
