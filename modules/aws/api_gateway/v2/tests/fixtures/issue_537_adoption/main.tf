terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.54.0"
    }
  }
}

locals {
  function_arn = "arn:aws:lambda:us-east-1:123456789012:function:webhook"
  log_arn      = "arn:aws:logs:us-east-1:123456789012:log-group:/example/webhook"
  log_format = jsonencode({
    requestId          = "$context.requestId"
    status             = "$context.status"
    responseLength     = "$context.responseLength"
    integrationLatency = "$context.integrationLatency"
  })
}

module "tables" {
  source = "../../../../../dynamodb/table"

  tables = {
    webhook = {
      name      = "webhook-events"
      hash_key  = "pk"
      attribute = [{ name = "pk", type = "S" }]
      ttl       = { enabled = true, attribute_name = "ttl" }
    }
  }
}

module "dlq" {
  source = "../../../../../sqs_queue"

  name                      = "webhook-dlq"
  create_kms_key            = false
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600
}

module "queues" {
  source   = "../../../../../sqs_queue"
  for_each = toset(["work"])

  name                       = "webhook-${each.key}"
  create_kms_key             = false
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 720
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.dlq.arn
    maxReceiveCount     = 5
  })
}

module "mapping" {
  source = "../../../../../lambda_event_source_mapping"

  function_name                      = local.function_arn
  event_source_arn                   = module.queues["work"].arn
  batch_size                         = 10
  enabled                            = true
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
}

module "http" {
  source = "../../.."

  name          = "webhook"
  protocol_type = "HTTP"
  integrations = {
    webhook = {
      integration_type       = "AWS_PROXY"
      integration_method     = "POST"
      integration_uri        = local.function_arn
      payload_format_version = "2.0"
    }
  }
  routes = {
    webhook = {
      route_key          = "POST /webhook/{token}"
      authorization_type = "NONE"
      integration_key    = "webhook"
    }
  }
  stages = {
    "$default" = {
      auto_deploy = true
      access_log_settings = {
        destination_arn = local.log_arn
        format          = local.log_format
      }
    }
  }
}

output "adoption" {
  description = "Deterministic cross-module identifiers and delivery controls."
  value = {
    table_names        = module.tables.table_names
    dlq_arn            = module.dlq.arn
    work_arn           = module.queues["work"].arn
    work_url           = module.queues["work"].url
    mapping_source     = module.mapping.event_source_arn
    mapping_uuid       = module.mapping.uuid
    mapping_batch_size = module.mapping.batch_size
    mapping_window     = module.mapping.maximum_batching_window_in_seconds
    mapping_responses  = module.mapping.function_response_types
    execution_arn      = module.http.execution_arn
    endpoint           = module.http.api_endpoint
    integration_ids    = module.http.integration_ids
    route_ids          = module.http.route_ids
    stage_ids          = module.http.stage_ids
    stage_invoke_urls  = module.http.stage_invoke_urls
    log_format         = local.log_format
    created_key_arns   = [module.dlq.kms_key_arn, module.queues["work"].kms_key_arn]
  }
}
