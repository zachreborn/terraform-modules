# No real infrastructure, credentials, backend, or application tokens are used.
mock_provider "aws" {
  mock_resource "aws_dynamodb_table" {
    defaults = {
      id     = "webhook-events"
      arn    = "arn:aws:dynamodb:us-east-1:123456789012:table/webhook-events"
      region = "us-east-1"
      point_in_time_recovery = {
        recovery_period_in_days = 35
      }
      server_side_encryption = {
        kms_key_arn = "arn:aws:kms:us-east-1:123456789012:key/aaaaaaaa-bbbb-4ccc-8ddd-eeeeeeeeeeee"
      }
    }
  }
  mock_resource "aws_lambda_event_source_mapping" {
    defaults = {
      id           = "11111111-2222-4333-8444-555555555555"
      uuid         = "11111111-2222-4333-8444-555555555555"
      arn          = "arn:aws:lambda:us-east-1:123456789012:event-source-mapping:11111111-2222-4333-8444-555555555555"
      function_arn = "arn:aws:lambda:us-east-1:123456789012:function:webhook"
      region       = "us-east-1"
    }
  }
  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      id            = "exampleapi"
      api_endpoint  = "https://exampleapi.execute-api.us-east-1.amazonaws.com"
      arn           = "arn:aws:apigateway:us-east-1::/apis/exampleapi"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:exampleapi"
      region        = "us-east-1"
    }
  }
  mock_resource "aws_apigatewayv2_integration" {
    defaults = { id = "exampleintegration", region = "us-east-1" }
  }
  mock_resource "aws_apigatewayv2_route" {
    defaults = { id = "exampleroute", region = "us-east-1" }
  }
  mock_resource "aws_apigatewayv2_stage" {
    defaults = {
      id            = "$default"
      invoke_url    = "https://exampleapi.execute-api.us-east-1.amazonaws.com/"
      arn           = "arn:aws:apigateway:us-east-1::/apis/exampleapi/stages/$default"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:exampleapi/$default"
      region        = "us-east-1"
    }
  }
}

run "eight_resource_adoption_wiring" {
  command = apply

  module {
    source = "./tests/fixtures/issue_537_adoption"
  }

  override_resource {
    target = module.dlq.aws_sqs_queue.queue
    values = {
      arn                  = "arn:aws:sqs:us-east-1:123456789012:webhook-dlq"
      id                   = "https://sqs.us-east-1.amazonaws.com/123456789012/webhook-dlq"
      url                  = "https://sqs.us-east-1.amazonaws.com/123456789012/webhook-dlq"
      region               = "us-east-1"
      policy               = ""
      redrive_policy       = ""
      redrive_allow_policy = ""
    }
  }
  override_resource {
    target = module.queues["work"].aws_sqs_queue.queue
    values = {
      arn                  = "arn:aws:sqs:us-east-1:123456789012:webhook-work"
      id                   = "https://sqs.us-east-1.amazonaws.com/123456789012/webhook-work"
      url                  = "https://sqs.us-east-1.amazonaws.com/123456789012/webhook-work"
      region               = "us-east-1"
      policy               = ""
      redrive_allow_policy = ""
    }
  }

  assert {
    condition     = output.adoption.table_names == tomap({ webhook = "webhook-events" })
    error_message = "The table must retain its physical name and logical key."
  }
  assert {
    condition     = output.adoption.mapping_source == "arn:aws:sqs:us-east-1:123456789012:webhook-work" && output.adoption.mapping_source == output.adoption.work_arn
    error_message = "The mapping must consume the real work module's queue ARN."
  }
  assert {
    condition     = output.adoption.mapping_uuid == "11111111-2222-4333-8444-555555555555" && output.adoption.mapping_batch_size == 10 && output.adoption.mapping_window == 5 && output.adoption.mapping_responses == toset(["ReportBatchItemFailures"])
    error_message = "Mapping identity and batch delivery controls must be exact."
  }
  assert {
    condition     = output.adoption.integration_ids == tomap({ webhook = "exampleintegration" }) && output.adoption.route_ids == tomap({ webhook = "exampleroute" }) && output.adoption.stage_ids == tomap({ "$default" = "$default" })
    error_message = "API child outputs must retain exact keys and provider identifiers."
  }
  assert {
    condition     = output.adoption.execution_arn == "arn:aws:execute-api:us-east-1:123456789012:exampleapi" && output.adoption.endpoint == "https://exampleapi.execute-api.us-east-1.amazonaws.com"
    error_message = "API execution ARN and endpoint must remain available."
  }
  assert {
    condition     = alltrue([for arn in output.adoption.created_key_arns : arn == null]) && toset(keys(jsondecode(output.adoption.log_format))) == toset(["requestId", "status", "responseLength", "integrationLatency"])
    error_message = "Adoption must create no keys and must exclude token-bearing fields from logs."
  }
}
