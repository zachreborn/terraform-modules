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



run "websocket_authorizer_authorizer_type" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type" = "JWT"
        "jwt_configuration" = {
          "audience" = ["fake"]
          "issuer"   = "https://issuer.invalid"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "websocket_authorizer_authorizer_payload_format_version" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "websocket_authorizer_enable_simple_responses" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    authorizers = {
      "bad" = {
        "authorizer_type"         = "REQUEST"
        "enable_simple_responses" = false
      }
    }
  }
  expect_failures = [aws_apigatewayv2_authorizer.this["bad"]]
}

run "mtls_conflict" {
  command = plan
  variables {
    mutual_tls_authentication = {
      "truststore_uri" = "s3://fake/global"
    }
    domain_names = {
      "bad" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "mutual_tls_authentication" = {
          "truststore_uri" = "s3://fake/local"
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_domain_name.this["bad"]]
}

run "connection_both" {
  command = plan
  variables {
    protocol_type = "HTTP"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "connection_id"    = "literal"
        "vpc_link_key"     = "existing"
      }
    }
    vpc_links = {
      "existing" = {
        "security_group_ids" = ["sg-12345678"]
        "subnet_ids"         = ["subnet-12345678"]
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "connection_unknown" {
  command = plan
  variables {
    protocol_type = "HTTP"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "vpc_link_key"     = "missing"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_timeout" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type"     = "AWS_PROXY"
        "timeout_milliseconds" = 29001
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "http_content" {
  command = plan
  variables {
    protocol_type = "HTTP"
    integrations = {
      "bad" = {
        "integration_type"          = "AWS_PROXY"
        "content_handling_strategy" = "CONVERT_TO_TEXT"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_subtype" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type"    = "AWS_PROXY"
        "integration_subtype" = "SQS-SendMessage"
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}

run "websocket_responses" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "bad" = {
        "integration_type" = "AWS_PROXY"
        "response_parameters" = {
          "ok" = {
            "status_code" = "200"
            "mappings" = {
              "append:header.x" = "x"
            }
          }
        }
      }
    }
  }
  expect_failures = [aws_apigatewayv2_integration.this["bad"]]
}