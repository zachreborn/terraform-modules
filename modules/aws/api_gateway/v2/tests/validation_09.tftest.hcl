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