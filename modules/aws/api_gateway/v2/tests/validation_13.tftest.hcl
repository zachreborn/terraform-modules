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

          "throttling_burst_limit" = 10
          "throttling_rate_limit"  = 10
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

          "throttling_burst_limit" = 10
          "throttling_rate_limit"  = 10
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

            "throttling_burst_limit" = 10
            "throttling_rate_limit"  = 10
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

            "throttling_burst_limit" = 10
            "throttling_rate_limit"  = 10
          }
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_stage.this["bad"]]
}