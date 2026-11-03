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