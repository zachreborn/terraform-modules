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
# CloudWatch EventBridge Rule
###########################
resource "aws_cloudwatch_event_rule" "event_rule" {
  description         = var.description
  event_bus_name      = var.event_bus_name
  event_pattern       = var.event_pattern
  name                = var.name
  name_prefix         = var.name_prefix
  role_arn            = var.role_arn
  schedule_expression = var.schedule_expression
  state               = var.state
  tags                = merge(tomap({ Name = coalesce(var.name, var.name_prefix, "cloudwatch-event") }), var.tags)

  lifecycle {
    precondition {
      condition     = (var.event_pattern != null) != (var.schedule_expression != null)
      error_message = "Exactly one of event_pattern or schedule_expression must be provided."
    }
    precondition {
      condition     = (var.name == null) != (var.name_prefix == null)
      error_message = "Exactly one of name or name_prefix must be provided."
    }
  }
}

###########################
# CloudWatch EventBridge Target
###########################
resource "aws_cloudwatch_event_target" "event_target" {
  arn            = var.event_target_arn
  event_bus_name = var.event_bus_name
  rule           = aws_cloudwatch_event_rule.event_rule.name
  target_id      = var.target_id

  dynamic "input_transformer" {
    for_each = var.input_transformer != null ? [var.input_transformer] : []
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }
}
