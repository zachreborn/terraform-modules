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

          "throttling_burst_limit" = 10
          "throttling_rate_limit"  = 10
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

            "throttling_burst_limit" = 10
            "throttling_rate_limit"  = 10
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

          "throttling_rate_limit" = 10
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

          "throttling_rate_limit" = 10
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

            "throttling_rate_limit" = 10
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

            "throttling_rate_limit" = 10
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

          "throttling_burst_limit" = 10
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

            "throttling_burst_limit" = 10
          }
        }
      }
    }
  }
  expect_failures = [var.stages]
}