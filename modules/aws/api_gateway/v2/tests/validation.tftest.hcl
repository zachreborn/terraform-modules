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

run "authorizers_null_element_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = null
    }
  }
  expect_failures = [var.authorizers]
}

run "domain_names_null_element_null" {
  command = plan
  variables {
    domain_names = {
      "bad" = null
    }
  }
  expect_failures = [var.domain_names]
}

run "integrations_null_element_null" {
  command = plan
  variables {
    integrations = {
      "bad" = null
    }
  }
  expect_failures = [var.integrations]
}

run "integration_responses_null_element_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integration_responses = {
      "bad" = null
    }
  }
  expect_failures = [var.integration_responses]
}

run "models_null_element_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    models = {
      "bad" = null
    }
  }
  expect_failures = [var.models]
}

run "routes_null_element_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = null
    }
  }
  expect_failures = [var.routes]
}

run "route_responses_null_element_null" {
  command = plan
  variables {
    route_responses = {
      "bad" = null
    }
  }
  expect_failures = [var.route_responses]
}

run "stages_null_element_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = null
    }
  }
  expect_failures = [var.stages]
}

run "vpc_links_null_element_null" {
  command = plan
  variables {
    vpc_links = {
      "bad" = null
    }
  }
  expect_failures = [var.vpc_links]
}

run "integrations_integration_type_invalid" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "INVALID"
      }
    }
  }
  expect_failures = [var.integrations]
}

run "integrations_integration_type_missing" {
  command = plan
  variables {
    integrations = {
      "bad" = {}
    }
  }
  expect_failures = [var.integrations]
}

run "integrations_connection_type_invalid" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "connection_type"  = "INVALID"
      }
    }
  }
  expect_failures = [var.integrations]
}

run "integrations_content_handling_strategy_invalid" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"          = "AWS_PROXY"
        "content_handling_strategy" = "INVALID"
      }
    }
  }
  expect_failures = [var.integrations]
}

run "integrations_passthrough_behavior_invalid" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"     = "AWS_PROXY"
        "passthrough_behavior" = "INVALID"
      }
    }
  }
  expect_failures = [var.integrations]
}

run "integrations_payload_format_version_invalid" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"       = "AWS_PROXY"
        "payload_format_version" = "INVALID"
      }
    }
  }
  expect_failures = [var.integrations]
}

run "integration_timeout_low" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"     = "AWS_PROXY"
        "timeout_milliseconds" = 49
      }
    }
  }
  expect_failures = [var.integrations]
}

run "integration_timeout_high" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"     = "AWS_PROXY"
        "timeout_milliseconds" = 30001
      }
    }
  }
  expect_failures = [var.integrations]
}

run "integration_timeout_fraction" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"     = "AWS_PROXY"
        "timeout_milliseconds" = 50.5
      }
    }
  }
  expect_failures = [var.integrations]
}

run "response_status_low" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "HTTP_PROXY"
        "response_parameters" = {
          "x" = {
            "status_code" = "199"
            "mappings"    = {}
          }
        }
      }
    }
  }
  expect_failures = [var.integrations]
}

run "response_status_high" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "HTTP_PROXY"
        "response_parameters" = {
          "x" = {
            "status_code" = "600"
            "mappings"    = {}
          }
        }
      }
    }
  }
  expect_failures = [var.integrations]
}

run "response_status_fraction" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "HTTP_PROXY"
        "response_parameters" = {
          "x" = {
            "status_code" = "200.5"
            "mappings"    = {}
          }
        }
      }
    }
  }
  expect_failures = [var.integrations]
}

run "response_status_null" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "HTTP_PROXY"
        "response_parameters" = {
          "x" = null
        }
      }
    }
  }
  expect_failures = [var.integrations]
}

run "routes_authorization_type_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key"          = "GET /"
        "authorization_type" = "INVALID"
      }
    }
  }
  expect_failures = [var.routes]
}

run "route_key_required_missing" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {}
    }
  }
  expect_failures = [var.routes]
}

run "route_key_required_empty" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key" = ""
      }
    }
  }
  expect_failures = [var.routes]
}

run "legacy_parameters_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key" = "$connect"
        "request_parameters" = {
          "route.request.querystring.x" = "yes"
        }
      }
    }
  }
  expect_failures = [var.routes]
}

run "legacy_parameters_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key" = "$connect"
        "request_parameters" = {
          "route.request.querystring.x" = null
        }
      }
    }
  }
  expect_failures = [var.routes]
}

run "parameter_conflict_both" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key" = "$connect"
        "request_parameter" = {
          "x" = {
            "request_parameter_key" = "route.request.querystring.x"
            "required"              = true
          }
        }
        "request_parameters" = {
          "route.request.querystring.y" = "false"
        }
      }
    }
  }
  expect_failures = [var.routes]
}

run "parameter_null_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key" = "$connect"
        "request_parameter" = {
          "x" = null
        }
      }
    }
  }
  expect_failures = [var.routes]
}

run "authorizers_authorizer_type_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type" = "INVALID"
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizers_authorizer_type_missing" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {}
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizers_authorizer_payload_format_version_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "INVALID"
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizer_result_ttl_low" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "authorizer_result_ttl"             = -1
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizer_result_ttl_high" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "authorizer_result_ttl"             = 3601
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizer_result_ttl_fraction" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "authorizer_result_ttl"             = 1.5
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizer_result_ttl_in_seconds_low" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "authorizer_result_ttl_in_seconds"  = -1
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizer_result_ttl_in_seconds_high" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "authorizer_result_ttl_in_seconds"  = 3601
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "authorizer_result_ttl_in_seconds_fraction" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "authorizer_result_ttl_in_seconds"  = 1.5
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "ttl_conflict_both" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "authorizer_result_ttl"             = 0
        "authorizer_result_ttl_in_seconds"  = 300
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "simple_payload_v1" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "1.0"
        "enable_simple_responses"           = true
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "simple_payload_missing" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"         = "REQUEST"
        "enable_simple_responses" = true
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "domain_endpoint_type_invalid" {
  command = plan
  variables {
    domain_names = {
      "bad" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
          "endpoint_type"   = "INVALID"
        }
      }
    }
  }
  expect_failures = [var.domain_names]
}

run "domain_security_policy_invalid" {
  command = plan
  variables {
    domain_names = {
      "bad" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
          "security_policy" = "INVALID"
        }
      }
    }
  }
  expect_failures = [var.domain_names]
}

run "domain_ip_address_type_invalid" {
  command = plan
  variables {
    domain_names = {
      "bad" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
          "ip_address_type" = "INVALID"
        }
      }
    }
  }
  expect_failures = [var.domain_names]
}

run "domain_names_routing_mode_invalid" {
  command = plan
  variables {
    domain_names = {
      "bad" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "routing_mode" = "INVALID"
      }
    }
  }
  expect_failures = [var.domain_names]
}

run "model_json_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    models = {
      "Bad" = {
        "name"         = "ignored"
        "content_type" = "application/json"
        "schema"       = "{"
      }
    }
  }
  expect_failures = [var.models]
}

run "vpc_subnet_ids_empty" {
  command = plan
  variables {
    vpc_links = {
      "bad" = {
        "subnet_ids"         = []
        "security_group_ids" = ["sg-12345678"]
      }
    }
  }
  expect_failures = [var.vpc_links]
}

run "vpc_subnet_ids_null" {
  command = plan
  variables {
    vpc_links = {
      "bad" = {
        "subnet_ids"         = null
        "security_group_ids" = ["sg-12345678"]
      }
    }
  }
  expect_failures = [var.vpc_links]
}

run "vpc_security_group_ids_empty" {
  command = plan
  variables {
    vpc_links = {
      "bad" = {
        "subnet_ids"         = ["subnet-12345678"]
        "security_group_ids" = []
      }
    }
  }
  expect_failures = [var.vpc_links]
}

run "vpc_security_group_ids_null" {
  command = plan
  variables {
    vpc_links = {
      "bad" = {
        "subnet_ids"         = ["subnet-12345678"]
        "security_group_ids" = null
      }
    }
  }
  expect_failures = [var.vpc_links]
}

run "integration_responses_content_handling_strategy_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integration_responses = {
      "bad" = {
        "integration_id"            = "fake"
        "integration_response_key"  = "$default"
        "content_handling_strategy" = "INVALID"
      }
    }
  }
  expect_failures = [var.integration_responses]
}

run "settings_null_null" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "route_settings" = {
          "$default" = null
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_logging_level_default_route_settings_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "default_route_settings" = {
          "logging_level" = "INVALID"
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_logging_level_route_settings_invalid" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "route_settings" = {
          "$default" = {
            "logging_level" = "INVALID"
          }
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_throttling_burst_limit_default_route_settings_negative" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "default_route_settings" = {
          "throttling_burst_limit" = -1
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_throttling_burst_limit_default_route_settings_fraction" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "default_route_settings" = {
          "throttling_burst_limit" = 1.5
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_throttling_burst_limit_route_settings_negative" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "route_settings" = {
          "$default" = {
            "throttling_burst_limit" = -1
          }
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_throttling_burst_limit_route_settings_fraction" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "route_settings" = {
          "$default" = {
            "throttling_burst_limit" = 1.5
          }
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_throttling_rate_limit_default_route_settings_negative" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "default_route_settings" = {
          "throttling_rate_limit" = -1
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "stage_throttling_rate_limit_route_settings_negative" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "route_settings" = {
          "$default" = {
            "throttling_rate_limit" = -1
          }
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "access_logs_destination" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "access_log_settings" = {
          "destination_arn" = ""
          "format"          = "$context.requestId"
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "access_logs_format" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "access_log_settings" = {
          "destination_arn" = "arn:aws:logs:us-east-1:123456789012:log-group:fake"
          "format"          = ""
        }
      }
    }
  }
  expect_failures = [var.stages]
}

run "description_length_long" {
  command = plan
  variables {
    description = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }
  expect_failures = [var.description]
}

run "api_version_length_empty" {
  command = plan
  variables {
    api_version = ""
  }
  expect_failures = [var.api_version]
}

run "api_version_length_long" {
  command = plan
  variables {
    api_version = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
  }
  expect_failures = [var.api_version]
}

run "protocol_invalid" {
  command = plan
  variables {
    protocol_type = "REST"
  }
  expect_failures = [var.protocol_type]
}

run "protocol_null" {
  command = plan
  variables {
    protocol_type = null
  }
  expect_failures = [var.protocol_type]
}

run "ip_address_invalid" {
  command = plan
  variables {
    ip_address_type = "ipv6"
  }
  expect_failures = [var.ip_address_type]
}

run "cors_websocket" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    cors_configuration = {
      "allow_origins" = ["https://example.invalid"]
    }
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_websocket" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    body          = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_integrations" {
  command = plan
  variables {
    body = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_routes" {
  command = plan
  variables {
    body = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    routes = {
      "bad" = {
        "route_key" = "GET /"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_cors" {
  command = plan
  variables {
    body = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    cors_configuration = {
      "max_age" = 1
    }
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_version" {
  command = plan
  variables {
    body        = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    api_version = "1"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "quick_integrations" {
  command = plan
  variables {
    target = "https://example.invalid"
    integrations = {
      "bad" = {
        "integration_type" = "HTTP_PROXY"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "quick_routes" {
  command = plan
  variables {
    target = "https://example.invalid"
    routes = {
      "bad" = {
        "route_key" = "GET /"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "quick_stages" {
  command = plan
  variables {
    target = "https://example.invalid"
    stages = {
      "bad" = {}
    }
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "websocket_target" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    target        = "https://example.invalid"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "websocket_route_key" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    route_key     = "GET /"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "websocket_credentials_arn" {
  command = plan
  variables {
    protocol_type   = "WEBSOCKET"
    credentials_arn = "arn:aws:iam::123456789012:role/fake"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "websocket_fail_on_warnings" {
  command = plan
  variables {
    protocol_type    = "WEBSOCKET"
    fail_on_warnings = true
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_quick_target" {
  command = plan
  variables {
    body   = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    target = "https://example.invalid"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_quick_route_key" {
  command = plan
  variables {
    body      = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    route_key = "GET /"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "body_quick_credentials_arn" {
  command = plan
  variables {
    body            = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    credentials_arn = "arn:aws:iam::123456789012:role/fake"
  }
  expect_failures = [aws_apigatewayv2_api.this]
}

run "request_missing_payload" {
  command = plan
  variables {
    authorizers = {
      "bad" = {
        "authorizer_type" = "REQUEST"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "jwt_missing" {
  command = plan
  variables {
    authorizers = {
      "bad" = {
        "authorizer_type" = "JWT"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "jwt_empty_audience" {
  command = plan
  variables {
    authorizers = {
      "bad" = {
        "authorizer_type" = "JWT"
        "jwt_configuration" = {
          "audience" = []
          "issuer"   = "https://issuer.invalid"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "jwt_empty_issuer" {
  command = plan
  variables {
    authorizers = {
      "bad" = {
        "authorizer_type" = "JWT"
        "jwt_configuration" = {
          "audience" = ["fake"]
          "issuer"   = ""
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "jwt_conflict" {
  command = plan
  variables {
    jwt_configuration = {
      "audience" = ["fake"]
      "issuer"   = "https://issuer.invalid"
    }
    authorizers = {
      "bad" = {
        "authorizer_type" = "JWT"
        "jwt_configuration" = {
          "audience" = ["different"]
          "issuer"   = "https://issuer.invalid"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "request_nested_jwt" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "jwt_configuration" = {
          "audience" = ["fake"]
          "issuer"   = "https://issuer.invalid"
        }
      }
    }
  }
  expect_failures = [var.authorizers]
}

run "websocket_authorizer_authorizer_type" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type" = "JWT"
        "jwt_configuration" = {
          "audience" = ["fake"]
          "issuer"   = "https://issuer.invalid"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "websocket_authorizer_authorizer_payload_format_version" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "websocket_authorizer_enable_simple_responses" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"         = "REQUEST"
        "enable_simple_responses" = false
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "mtls_conflict" {
  command = plan
  variables {
    mutual_tls_authentication = {
      "truststore_uri" = "s3://fake/global"
    }
    domain_names = {
      "bad" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "mutual_tls_authentication" = {
          "truststore_uri" = "s3://fake/local"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_domain_name.this["bad"]]
}

run "connection_both" {
  command = plan
  variables {
    protocol_type = "HTTP"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "connection_id"    = "literal"
        "vpc_link_key"     = "existing"
      }
    }
    vpc_links = {
      "existing" = {
        "security_group_ids" = ["sg-12345678"]
        "subnet_ids"         = ["subnet-12345678"]
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "connection_unknown" {
  command = plan
  variables {
    protocol_type = "HTTP"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "vpc_link_key"     = "missing"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_timeout" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type"     = "AWS_PROXY"
        "timeout_milliseconds" = 29001
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "http_content" {
  command = plan
  variables {
    protocol_type = "HTTP"
    integrations = {
      "bad" = {
        "integration_type"          = "AWS_PROXY"
        "content_handling_strategy" = "CONVERT_TO_TEXT"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_subtype" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type"    = "AWS_PROXY"
        "integration_subtype" = "SQS-SendMessage"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_responses" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "response_parameters" = {
          "ok" = {
            "status_code" = "200"
            "mappings" = {
              "append:header.x" = "x"
            }
          }
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_tls" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "tls_config" = {
          "server_name_to_verify" = "example.invalid"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_payload" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type"       = "AWS_PROXY"
        "payload_format_version" = "2.0"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "route_target_both" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key"       = "GET /"
        "target"          = "integrations/literal"
        "integration_key" = "existing"
      }
    }
    integrations = {
      "existing" = {
        "integration_type" = "AWS_PROXY"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "route_integration_unknown" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key"       = "GET /"
        "integration_key" = "missing"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "route_authorizer_both" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key"      = "GET /"
        "authorizer_id"  = "literal"
        "authorizer_key" = "existing"
      }
    }
    authorizers = {
      "existing" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "route_authorizer_unknown" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key"      = "GET /"
        "authorizer_key" = "missing"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "route_target_format" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key" = "GET /"
        "target"    = "literal"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "http_route_api_key_required" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key"        = "GET /"
        "api_key_required" = true
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "http_route_model_selection_expression" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key"                  = "GET /"
        "model_selection_expression" = "$request.body.model"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "http_route_request_models" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key" = "GET /"
        "request_models" = {
          "x" = "fake"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "http_route_request_parameter" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key" = "GET /"
        "request_parameter" = {
          "x" = {
            "request_parameter_key" = "route.request.querystring.x"
            "required"              = true
          }
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "http_route_request_parameters" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key" = "GET /"
        "request_parameters" = {
          "route.request.querystring.x" = "true"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "http_route_route_response_selection_expression" {
  command = plan
  variables {
    routes = {
      "bad" = {
        "route_key"                           = "GET /"
        "route_response_selection_expression" = "$default"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "websocket_route_authorization_type" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key"          = "$connect"
        "authorization_type" = "JWT"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "websocket_route_authorization_scopes" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "bad" = {
        "route_key"            = "$connect"
        "authorization_scopes" = ["fake"]
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route.this["bad"]]
}

run "integration_response_neither" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integration_responses = {
      "bad" = {
        "integration_response_key" = "$default"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration_response.this["bad"]]
}

run "integration_response_both" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integration_responses = {
      "bad" = {
        "integration_response_key" = "$default"
        "integration_id"           = "literal"
        "integration_key"          = "existing"
      }
    }
    integrations = {
      "existing" = {
        "integration_type" = "MOCK"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration_response.this["bad"]]
}

run "integration_response_unknown" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integration_responses = {
      "bad" = {
        "integration_response_key" = "$default"
        "integration_key"          = "missing"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration_response.this["bad"]]
}

run "http_integration_response" {
  command = plan
  variables {
    integration_responses = {
      "bad" = {
        "integration_response_key" = "$default"
        "integration_id"           = "literal"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration_response.this["bad"]]
}

run "route_response_neither" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    route_responses = {
      "bad" = {
        "route_response_key" = "$default"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route_response.this["bad"]]
}

run "route_response_both" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    route_responses = {
      "bad" = {
        "route_response_key" = "$default"
        "route_id"           = "literal"
        "route_key"          = "existing"
      }
    }
    routes = {
      "existing" = {
        "route_key" = "$connect"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route_response.this["bad"]]
}

run "route_response_unknown" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    route_responses = {
      "bad" = {
        "route_response_key" = "$default"
        "route_key"          = "missing"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route_response.this["bad"]]
}

run "http_route_response" {
  command = plan
  variables {
    route_responses = {
      "bad" = {
        "route_response_key" = "$default"
        "route_id"           = "literal"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route_response.this["bad"]]
}

run "http_model" {
  command = plan
  variables {
    models = {
      "bad" = {
        "name"         = "ignored"
        "schema"       = "{}"
        "content_type" = "application/json"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_model.this["bad"]]
}

run "http_stage_certificate" {
  command = plan
  variables {
    stages = {
      "bad" = {
        "client_certificate_id" = "fake"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_stage.this["bad"]]
}

run "stage_deployment_conflict" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    stages = {
      "bad" = {
        "auto_deploy"   = true
        "deployment_id" = "fake"
      }
    }
  }
  expect_failures = [var.stages]
}

run "http_stage_default_route_settings_data_trace_enabled" {
  command = plan
  variables {
    stages = {
      "bad" = {
        "default_route_settings" = {
          "data_trace_enabled" = true
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_stage.this["bad"]]
}

run "http_stage_default_route_settings_logging_level" {
  command = plan
  variables {
    stages = {
      "bad" = {
        "default_route_settings" = {
          "logging_level" = "INFO"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_stage.this["bad"]]
}

run "http_stage_route_settings_data_trace_enabled" {
  command = plan
  variables {
    stages = {
      "bad" = {
        "route_settings" = {
          "GET /" = {
            "data_trace_enabled" = true
          }
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_stage.this["bad"]]
}

run "http_stage_route_settings_logging_level" {
  command = plan
  variables {
    stages = {
      "bad" = {
        "route_settings" = {
          "GET /" = {
            "logging_level" = "INFO"
          }
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_stage.this["bad"]]
}

run "http_integration_type_aws" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "AWS"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "http_integration_type_http" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "HTTP"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "http_integration_type_mock" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "MOCK"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "http_integration_passthrough_behavior" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"     = "HTTP_PROXY"
        "passthrough_behavior" = "WHEN_NO_MATCH"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "http_integration_request_templates" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type" = "HTTP_PROXY"
        "request_templates" = {
          "application/json" = "{}"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_private_connection_id" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    vpc_links = {
      "private" = {
        "security_group_ids" = ["sg-12345678"]
        "subnet_ids"         = ["subnet-12345678"]
      }
    }
    integrations = {
      "bad" = {
        "integration_type" = "AWS"
        "connection_id"    = "literal"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_private_connection_type" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    vpc_links = {
      "private" = {
        "security_group_ids" = ["sg-12345678"]
        "subnet_ids"         = ["subnet-12345678"]
      }
    }
    integrations = {
      "bad" = {
        "integration_type" = "AWS"
        "connection_type"  = "VPC_LINK"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_private_vpc_link_key" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    vpc_links = {
      "private" = {
        "security_group_ids" = ["sg-12345678"]
        "subnet_ids"         = ["subnet-12345678"]
      }
    }
    integrations = {
      "bad" = {
        "integration_type" = "AWS"
        "vpc_link_key"     = "private"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "subtype_requires_aws_proxy" {
  command = plan
  variables {
    integrations = {
      "bad" = {
        "integration_type"    = "HTTP_PROXY"
        "integration_subtype" = "SQS-SendMessage"
      }
    }
  }
  expect_failures = [var.integrations]
}

run "route_response_actual_route_not_logical_key" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "logical" = {
        "route_key" = "$connect"
      }
    }
    route_responses = {
      "bad" = {
        "route_key"          = "$connect"
        "route_response_key" = "$default"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_route_response.this["bad"]]
}
