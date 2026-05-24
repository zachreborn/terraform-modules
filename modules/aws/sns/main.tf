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
# Data Sources
###########################


###########################
# Locals
###########################

###########################
# Module Configuration
###########################

###########################
# SNS Topic
###########################
resource "aws_sns_topic" "this" {
  application_failure_feedback_role_arn    = var.application_failure_feedback_role_arn
  application_success_feedback_role_arn    = var.application_success_feedback_role_arn
  application_success_feedback_sample_rate = var.application_success_feedback_sample_rate
  content_based_deduplication              = var.content_based_deduplication
  delivery_policy                          = var.delivery_policy
  display_name                             = var.display_name
  fifo_topic                               = var.fifo_topic
  firehose_failure_feedback_role_arn       = var.firehose_failure_feedback_role_arn
  firehose_success_feedback_role_arn       = var.firehose_success_feedback_role_arn
  firehose_success_feedback_sample_rate    = var.firehose_success_feedback_sample_rate
  http_failure_feedback_role_arn           = var.http_failure_feedback_role_arn
  http_success_feedback_role_arn           = var.http_success_feedback_role_arn
  http_success_feedback_sample_rate        = var.http_success_feedback_sample_rate
  kms_master_key_id                        = var.kms_master_key_id
  lambda_failure_feedback_role_arn         = var.lambda_failure_feedback_role_arn
  lambda_success_feedback_role_arn         = var.lambda_success_feedback_role_arn
  lambda_success_feedback_sample_rate      = var.lambda_success_feedback_sample_rate
  name                                     = var.fifo_topic ? "${var.name}.fifo" : var.name
  name_prefix                              = var.name_prefix
  signature_version                        = var.signature_version
  sqs_failure_feedback_role_arn            = var.sqs_failure_feedback_role_arn
  sqs_success_feedback_role_arn            = var.sqs_success_feedback_role_arn
  sqs_success_feedback_sample_rate         = var.sqs_success_feedback_sample_rate
  tags                                     = merge(tomap({ Name = var.name != null ? var.name : var.name_prefix }), var.tags)
  tracing_config                           = var.tracing_config
}

###########################
# SNS Topic Policy
###########################
resource "aws_sns_topic_policy" "this" {
  count  = var.policy != null ? 1 : 0
  arn    = aws_sns_topic.this.arn
  policy = var.policy
}

###########################
# SNS Topic Subscriptions
###########################
resource "aws_sns_topic_subscription" "this" {
  for_each = var.subscriptions

  confirmation_timeout_in_minutes = each.value.confirmation_timeout_in_minutes
  delivery_policy                 = each.value.delivery_policy
  endpoint                        = each.value.endpoint
  endpoint_auto_confirms          = each.value.endpoint_auto_confirms
  filter_policy                   = each.value.filter_policy
  filter_policy_scope             = each.value.filter_policy_scope
  protocol                        = each.value.protocol
  raw_message_delivery            = each.value.raw_message_delivery
  redrive_policy                  = each.value.redrive_policy
  replay_policy                   = each.value.replay_policy
  subscription_role_arn           = each.value.subscription_role_arn
  topic_arn                       = aws_sns_topic.this.arn
}
