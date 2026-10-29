mock_provider "aws" {
  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      "id"            = "api123"
      "api_endpoint"  = "https://api123.execute-api.us-east-1.amazonaws.com"
      "arn"           = "arn:aws:apigateway:us-east-1::/apis/api123"
      "execution_arn" = "arn:aws:execute-api:us-east-1:123456789012:api123"
      "tags_all" = {
        "Name"      = "fixture"
        "terraform" = "true"
      }
    }
  }
  mock_resource "aws_apigatewayv2_integration" {
    defaults = {
      "id"                                        = "int123"
      "integration_response_selection_expression" = "$default"
    }
  }
  mock_resource "aws_apigatewayv2_route" {
    defaults = {
      "id" = "route123"
    }
  }
  mock_resource "aws_apigatewayv2_authorizer" {
    defaults = {
      "id" = "auth123"
    }
  }
  mock_resource "aws_apigatewayv2_model" {
    defaults = {
      "id" = "model123"
    }
  }
  mock_resource "aws_apigatewayv2_integration_response" {
    defaults = {
      "id" = "ir123"
    }
  }
  mock_resource "aws_apigatewayv2_route_response" {
    defaults = {
      "id" = "rr123"
    }
  }
  mock_resource "aws_apigatewayv2_stage" {
    defaults = {
      "id"            = "stage123"
      "arn"           = "arn:aws:apigateway:us-east-1::/apis/api123/stages/stage123"
      "invoke_url"    = "https://api123.execute-api.us-east-1.amazonaws.com/stage123"
      "execution_arn" = "arn:aws:execute-api:us-east-1:123456789012:api123/stage123"
      "tags_all" = {
        "Name"    = "stage"
        "fixture" = "true"
      }
    }
  }
  mock_resource "aws_apigatewayv2_vpc_link" {
    defaults = {
      "id"  = "vpc123"
      "arn" = "arn:aws:apigateway:us-east-1::/vpclinks/vpc123"
      "tags_all" = {
        "Name"    = "link"
        "fixture" = "true"
      }
    }
  }
  mock_resource "aws_apigatewayv2_domain_name" {
    defaults = {
      "id"                               = "api.example.invalid"
      "arn"                              = "arn:aws:apigateway:us-east-1::/domainnames/api.example.invalid"
      "api_mapping_selection_expression" = "$request.basepath"
      "tags_all" = {
        "Name"    = "api.example.invalid"
        "fixture" = "true"
      }
      "domain_name_configuration" = {
        "target_domain_name" = "d-fake.execute-api.us-east-1.amazonaws.com"
        "hosted_zone_id"     = "ZFAKE"
      }
    }
  }
}
variables {
  name          = "fixture"
  protocol_type = "HTTP"
}

run "required_http" {
  command = apply
  variables {
    integrations = {
      "webhook" = {
        "integration_type"       = "AWS_PROXY"
        "integration_method"     = "POST"
        "integration_uri"        = "arn:aws:lambda:us-east-1:123456789012:function:fake"
        "payload_format_version" = "2.0"
      }
    }
    routes = {
      "webhook" = {
        "route_key"          = "POST /webhook/{token}"
        "authorization_type" = "NONE"
        "integration_key"    = "webhook"
      }
    }
    stages = {
      "$default" = {
        "auto_deploy" = true
        "access_log_settings" = {
          "destination_arn" = "arn:aws:logs:us-east-1:123456789012:log-group:fake-access"
          "format"          = "{\"requestId\":\"$context.requestId\",\"status\":\"$context.status\",\"responseLength\":\"$context.responseLength\",\"latency\":\"$context.responseLatency\"}"
        }
      }
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_integration.this) == 1 && length(aws_apigatewayv2_route.this) == 1 && length(aws_apigatewayv2_stage.this) == 1
    error_message = "The HTTP application has exactly one of each application resource."
  }
  assert {
    condition     = aws_apigatewayv2_integration.this["webhook"].integration_method == "POST" && aws_apigatewayv2_integration.this["webhook"].payload_format_version == "2.0" && aws_apigatewayv2_integration.this["webhook"].integration_uri == "arn:aws:lambda:us-east-1:123456789012:function:fake"
    error_message = "POST and payload 2.0 reach the Lambda integration."
  }
  assert {
    condition     = aws_apigatewayv2_route.this["webhook"].route_key == "POST /webhook/{token}" && aws_apigatewayv2_route.this["webhook"].authorization_type == "NONE"
    error_message = "Route authorization remains application-controlled."
  }
  assert {
    condition     = aws_apigatewayv2_route.this["webhook"].target == "integrations/int123"
    error_message = "Integration ID wiring includes the required prefix."
  }
  assert {
    condition     = aws_apigatewayv2_stage.this["$default"].auto_deploy && aws_apigatewayv2_stage.this["$default"].access_log_settings[0].destination_arn == "arn:aws:logs:us-east-1:123456789012:log-group:fake-access" && aws_apigatewayv2_stage.this["$default"].access_log_settings[0].format == "{\"requestId\":\"$context.requestId\",\"status\":\"$context.status\",\"responseLength\":\"$context.responseLength\",\"latency\":\"$context.responseLatency\"}"
    error_message = "Auto-deployment and safe external access logging are exact."
  }
  assert {
    condition     = length(output.cors_configuration) == 0
    error_message = "Default CORS remains omitted."
  }
  assert {
    condition     = aws_apigatewayv2_api.this.api_key_selection_expression == "$request.header.x-api-key" && aws_apigatewayv2_api.this.route_selection_expression == "$request.method $request.path" && !aws_apigatewayv2_api.this.disable_execute_api_endpoint && !aws_apigatewayv2_api.this.fail_on_warnings
    error_message = "Baseline defaults preserve legacy behavior."
  }
  assert {
    condition     = output.id == "api123"
    error_message = "id matches deterministic provider metadata."
  }
  assert {
    condition     = output.api_endpoint == "https://api123.execute-api.us-east-1.amazonaws.com"
    error_message = "api_endpoint matches deterministic provider metadata."
  }
  assert {
    condition     = output.arn == "arn:aws:apigateway:us-east-1::/apis/api123"
    error_message = "arn matches deterministic provider metadata."
  }
  assert {
    condition     = output.execution_arn == "arn:aws:execute-api:us-east-1:123456789012:api123"
    error_message = "execution_arn matches deterministic provider metadata."
  }
  assert {
    condition     = output.tags_all == tomap({ "Name" = "fixture", "terraform" = "true" })
    error_message = "tags_all matches deterministic provider metadata."
  }
  assert {
    condition     = output.api_key_selection_expression == "$request.header.x-api-key"
    error_message = "Selection-expression output is preserved."
  }
  assert {
    condition     = output.integration_ids == tomap({ "webhook" = "int123" })
    error_message = "integration_ids preserves exact keys and values."
  }
  assert {
    condition     = output.route_ids == tomap({ "webhook" = "route123" })
    error_message = "route_ids preserves exact keys and values."
  }
  assert {
    condition     = output.stage_ids == tomap({ "$default" = "stage123" })
    error_message = "stage_ids preserves exact keys and values."
  }
  assert {
    condition     = output.stage_arns == tomap({ "$default" = "arn:aws:apigateway:us-east-1::/apis/api123/stages/stage123" })
    error_message = "stage_arns preserves exact keys and values."
  }
  assert {
    condition     = output.stage_invoke_urls == tomap({ "$default" = "https://api123.execute-api.us-east-1.amazonaws.com/stage123" })
    error_message = "stage_invoke_urls preserves exact keys and values."
  }
  assert {
    condition     = output.stage_execution_arns == tomap({ "$default" = "arn:aws:execute-api:us-east-1:123456789012:api123/stage123" })
    error_message = "stage_execution_arns preserves exact keys and values."
  }
  assert {
    condition     = output.integration_response_selection_expressions == tomap({ "webhook" = "$default" })
    error_message = "integration_response_selection_expressions preserves exact keys and values."
  }
  assert {
    condition     = output.stage_tags_all == tomap({ "$default" = tomap({ "Name" = "stage", "fixture" = "true" }) })
    error_message = "stage_tags_all preserves exact keys and values."
  }
  assert {
    condition     = output.authorizer_ids == tomap({})
    error_message = "authorizer_ids is an empty typed map when unused."
  }
  assert {
    condition     = output.model_ids == tomap({})
    error_message = "model_ids is an empty typed map when unused."
  }
  assert {
    condition     = output.integration_response_ids == tomap({})
    error_message = "integration_response_ids is an empty typed map when unused."
  }
  assert {
    condition     = output.route_response_ids == tomap({})
    error_message = "route_response_ids is an empty typed map when unused."
  }
  assert {
    condition     = output.vpc_link_ids == tomap({})
    error_message = "vpc_link_ids is an empty typed map when unused."
  }
  assert {
    condition     = output.vpc_link_arns == tomap({})
    error_message = "vpc_link_arns is an empty typed map when unused."
  }
  assert {
    condition     = output.domains == tomap({})
    error_message = "domains is an empty typed map when unused."
  }
  assert {
    condition     = output.domain_tags_all == tomap({})
    error_message = "domain_tags_all is an empty typed map when unused."
  }
  assert {
    condition     = output.vpc_link_tags_all == tomap({})
    error_message = "vpc_link_tags_all is an empty typed map when unused."
  }
}
