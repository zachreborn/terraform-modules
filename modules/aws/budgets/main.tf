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
  name             = var.name
  account_id       = var.account_id
  billing_view_arn = var.billing_view_arn
  budget_type      = var.budget_type
  limit_amount     = var.limit_amount
  limit_unit       = var.limit_unit
  time_unit        = var.time_unit

  time_period_start = var.time_period_start
  time_period_end   = var.time_period_end

  dynamic "auto_adjust_data" {
    for_each = var.auto_adjust_data != null ? [var.auto_adjust_data] : []
    content {
      auto_adjust_type = auto_adjust_data.value.auto_adjust_type

      dynamic "historical_options" {
        for_each = auto_adjust_data.value.historical_options != null ? [auto_adjust_data.value.historical_options] : []
        content {
          budget_adjustment_period = historical_options.value.budget_adjustment_period
        }
      }
    }
  }

  dynamic "cost_filter" {
    for_each = var.cost_filter
    content {
      name   = cost_filter.value.name
      values = cost_filter.value.values
    }
  }

  dynamic "cost_types" {
    for_each = var.cost_types != null ? [var.cost_types] : []
    content {
      include_credit             = cost_types.value.include_credit
      include_discount           = cost_types.value.include_discount
      include_other_subscription = cost_types.value.include_other_subscription
      include_recurring          = cost_types.value.include_recurring
      include_refund             = cost_types.value.include_refund
      include_subscription       = cost_types.value.include_subscription
      include_support            = cost_types.value.include_support
      include_tax                = cost_types.value.include_tax
      include_upfront            = cost_types.value.include_upfront
      use_amortized              = cost_types.value.use_amortized
      use_blended                = cost_types.value.use_blended
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

  dynamic "planned_limit" {
    for_each = var.planned_limit
    content {
      start_time = planned_limit.value.start_time
      amount     = planned_limit.value.amount
      unit       = planned_limit.value.unit
    }
  }

  tags = merge(tomap({ Name = var.name }), var.tags)
}
