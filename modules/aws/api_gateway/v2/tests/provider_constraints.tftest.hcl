mock_provider "aws" {}

variables {
  name          = "provider-constraints"
  protocol_type = "HTTP"
}

run "metrics_only_default_settings" {
  command = plan
  variables {
    stages = { test = { default_route_settings = { detailed_metrics_enabled = true } } }
  }
  expect_failures = [var.stages]
}

run "metrics_only_route_does_not_inherit_positive_stage_limits" {
  command = plan
  variables {
    stages = {
      test = {
        default_route_settings = { throttling_burst_limit = 100, throttling_rate_limit = 50 }
        route_settings         = { "GET /" = { detailed_metrics_enabled = true } }
      }
    }
  }
  expect_failures = [var.stages]
}

run "default_missing_burst" {
  command = plan
  variables {
    stages = { test = { default_route_settings = { throttling_rate_limit = 5 } } }
  }
  expect_failures = [var.stages]
}

run "default_missing_rate" {
  command = plan
  variables {
    stages = { test = { default_route_settings = { throttling_burst_limit = 10 } } }
  }
  expect_failures = [var.stages]
}

run "route_missing_burst" {
  command = plan
  variables {
    stages = { test = { route_settings = { "GET /" = { throttling_rate_limit = 5 } } } }
  }
  expect_failures = [var.stages]
}

run "route_missing_rate" {
  command = plan
  variables {
    stages = { test = { route_settings = { "GET /" = { throttling_burst_limit = 10 } } } }
  }
  expect_failures = [var.stages]
}

run "explicit_zero_limits_preserved" {
  command = plan
  variables {
    stages = {
      test = {
        default_route_settings = { throttling_burst_limit = 0, throttling_rate_limit = 0 }
        route_settings         = { "GET /" = { throttling_burst_limit = 0, throttling_rate_limit = 0 } }
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_stage.this["test"].default_route_settings[0].throttling_burst_limit == 0 && aws_apigatewayv2_stage.this["test"].default_route_settings[0].throttling_rate_limit == 0 && one(aws_apigatewayv2_stage.this["test"].route_settings).throttling_burst_limit == 0 && one(aws_apigatewayv2_stage.this["test"].route_settings).throttling_rate_limit == 0
    error_message = "Intentional zeros must remain explicit at both levels."
  }
}

run "internet_tls_rejected" {
  command = plan
  variables {
    integrations = {
      test = {
        integration_type = "HTTP_PROXY"
        connection_type  = "INTERNET"
        tls_config       = { server_name_to_verify = "example.invalid" }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["test"]]
}

run "aws_proxy_tls_rejected" {
  command = plan
  variables {
    integrations = {
      test = {
        integration_type = "AWS_PROXY"
        connection_type  = "VPC_LINK"
        connection_id    = "external-link"
        tls_config       = { server_name_to_verify = "example.invalid" }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["test"]]
}

run "jwt_payload_format_rejected" {
  command = plan
  variables {
    authorizers = {
      test = {
        authorizer_type                   = "JWT"
        jwt_configuration                 = { audience = ["fixture"], issuer = "https://issuer.invalid" }
        authorizer_payload_format_version = "1.0"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["test"]]
}

run "jwt_simple_responses_rejected" {
  command = plan
  variables {
    authorizers = {
      test = {
        authorizer_type                   = "JWT"
        jwt_configuration                 = { audience = ["fixture"], issuer = "https://issuer.invalid" }
        authorizer_payload_format_version = "2.0"
        enable_simple_responses           = true
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["test"]]
}

run "duplicate_status_codes_rejected" {
  command = plan
  variables {
    integrations = {
      test = {
        integration_type = "HTTP_PROXY"
        response_parameters = {
          first  = { status_code = "200", mappings = { "append:header.x" = "first" } }
          second = { status_code = "200", mappings = { "append:header.x" = "second" } }
        }
      }
    }
  }
  expect_failures = [var.integrations]
}

run "duplicate_parameter_keys_rejected" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      test = {
        route_key = "$connect"
        request_parameter = {
          first  = { request_parameter_key = "route.request.querystring.x", required = true }
          second = { request_parameter_key = "route.request.querystring.x", required = false }
        }
      }
    }
  }
  expect_failures = [var.routes]
}

run "distinct_status_codes_and_per_integration_scope" {
  command = plan
  variables {
    integrations = {
      first = {
        integration_type = "HTTP_PROXY"
        response_parameters = {
          success = { status_code = "200", mappings = { "append:header.x" = "success" } }
          failure = { status_code = "400", mappings = { "append:header.x" = "failure" } }
        }
      }
      second = {
        integration_type = "HTTP_PROXY"
        response_parameters = {
          success = { status_code = "200", mappings = { "append:header.x" = "second" } }
        }
      }
    }
  }
  assert {
    condition     = tomap({ for p in aws_apigatewayv2_integration.this["first"].response_parameters : p.status_code => p.mappings["append:header.x"] }) == tomap({ "200" = "success", "400" = "failure" }) && one(aws_apigatewayv2_integration.this["second"].response_parameters).mappings["append:header.x"] == "second"
    error_message = "Distinct status mappings must survive and keys are scoped per integration."
  }
}

run "distinct_parameter_keys_and_per_route_scope" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      first = {
        route_key = "$connect"
        request_parameter = {
          x = { request_parameter_key = "route.request.querystring.x", required = true }
          y = { request_parameter_key = "route.request.querystring.y", required = false }
        }
      }
      second = {
        route_key = "$disconnect"
        request_parameter = {
          x = { request_parameter_key = "route.request.querystring.x", required = false }
        }
      }
    }
  }
  assert {
    condition     = tomap({ for p in aws_apigatewayv2_route.this["first"].request_parameter : p.request_parameter_key => p.required }) == tomap({ "route.request.querystring.x" = true, "route.request.querystring.y" = false }) && !one(aws_apigatewayv2_route.this["second"].request_parameter).required
    error_message = "Distinct constraints must survive and keys are scoped per route."
  }
}
