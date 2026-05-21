##############################
# Provider Configuration
##############################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# Budget
##############################

resource "aws_budgets_budget" "this" {
  name         = var.name
  account_id   = var.account_id
  budget_type  = var.budget_type
  limit_amount = var.limit_amount
  limit_unit   = var.limit_unit
  time_unit    = var.time_unit

  time_period_start = var.time_period_start
  time_period_end   = var.time_period_end

  dynamic "cost_filter" {
    for_each = var.cost_filter
    content {
      name   = cost_filter.value.name
      values = cost_filter.value.values
    }
  }

  dynamic "notification" {
    for_each = var.notification
    content {
      comparison_operator        = notification.value.comparison_operator
      notification_type          = notification.value.notification_type
      threshold                  = notification.value.threshold
      threshold_type             = notification.value.threshold_type
      subscriber_email_addresses = try(notification.value.subscriber_email_addresses, [])
      subscriber_sns_topic_arns  = try(notification.value.subscriber_sns_topic_arns, [])
    }
  }

  tags = var.tags
}
