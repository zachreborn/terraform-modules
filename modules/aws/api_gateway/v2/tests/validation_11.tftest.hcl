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