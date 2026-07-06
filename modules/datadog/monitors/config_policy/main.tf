###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.3.0"
  required_providers {
    datadog = {
      source  = "DataDog/datadog"
      version = ">= 4.0.0"
    }
  }
}

###########################
# Locals
###########################

###########################
# Module Configuration
###########################

resource "datadog_monitor_config_policy" "this" {
  for_each = var.config_policies

  policy_type = each.value.policy_type

  dynamic "tag_policy" {
    for_each = each.value.tag_policy != null ? [each.value.tag_policy] : []
    content {
      tag_key          = tag_policy.value.tag_key
      tag_key_required = tag_policy.value.tag_key_required
      valid_tag_values = tag_policy.value.valid_tag_values
    }
  }
}
