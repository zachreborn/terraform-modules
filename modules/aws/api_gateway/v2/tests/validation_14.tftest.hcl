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
