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

resource "datadog_monitor_notification_rule" "this" {
  for_each = var.notification_rules

  name       = each.value.name
  recipients = each.value.recipients

  filter {
    scope = each.value.filter.scope
    tags  = each.value.filter.tags
  }

  dynamic "conditional_recipients" {
    for_each = each.value.conditional_recipients != null ? [each.value.conditional_recipients] : []
    content {
      fallback_recipients = conditional_recipients.value.fallback_recipients

      dynamic "conditions" {
        for_each = conditional_recipients.value.conditions != null ? conditional_recipients.value.conditions : []
        content {
          scope      = conditions.value.scope
          recipients = conditions.value.recipients
        }
      }
    }
  }
}
