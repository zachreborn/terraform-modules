terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
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
  name_prefix         = var.name_prefix
  role_arn            = var.role_arn
  schedule_expression = var.schedule_expression
  state               = var.state
  tags                = var.tags
}

###########################
# CloudWatch EventBridge Target
###########################
resource "aws_cloudwatch_event_target" "event_target" {
  arn       = var.event_target_arn
  rule      = aws_cloudwatch_event_rule.event_rule.name
  target_id = var.target_id

  dynamic "input_transformer" {
    for_each = var.input_transformer != null ? toset(var.input_transformer) : []
    content {
      input_paths    = input_transformer.value.input_paths
      input_template = input_transformer.value.input_template
    }
  }
}
