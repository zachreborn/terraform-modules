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