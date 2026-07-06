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
# Module Configuration
###########################
resource "datadog_integration_slack_channel" "this" {
  for_each = var.slack_channels

  account_name = each.value.account_name
  channel_name = each.value.channel_name

  display {
    message      = each.value.display.message
    mute_buttons = each.value.display.mute_buttons
    notified     = each.value.display.notified
    snapshot     = each.value.display.snapshot
    tags         = each.value.display.tags
  }
}
