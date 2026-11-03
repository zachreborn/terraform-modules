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