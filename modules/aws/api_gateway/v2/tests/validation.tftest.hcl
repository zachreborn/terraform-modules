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