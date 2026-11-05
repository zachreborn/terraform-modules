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

run "empty_maps" {
  command = plan
  assert {
    condition     = output.integration_ids == tomap({})
    error_message = "integration_ids is empty."
  }
  assert {
    condition     = output.route_ids == tomap({})
    error_message = "route_ids is empty."
  }
  assert {
    condition     = output.stage_ids == tomap({})
    error_message = "stage_ids is empty."
  }
  assert {
    condition     = output.authorizer_ids == tomap({})
    error_message = "authorizer_ids is empty."
  }
  assert {
    condition     = output.domains == tomap({})
    error_message = "domains is empty."
  }
  assert {
    condition     = output.model_ids == tomap({})
    error_message = "model_ids is empty."
  }
  assert {
    condition     = output.integration_response_ids == tomap({})
    error_message = "integration_response_ids is empty."
  }
  assert {
    condition     = output.route_response_ids == tomap({})
    error_message = "route_response_ids is empty."
  }
  assert {
    condition     = output.vpc_link_ids == tomap({})
    error_message = "vpc_link_ids is empty."
  }
  assert {
    condition     = output.vpc_link_arns == tomap({})
    error_message = "vpc_link_arns is empty."
  }
  assert {
    condition     = output.stage_arns == tomap({})
    error_message = "stage_arns is empty."
  }
  assert {
    condition     = output.stage_invoke_urls == tomap({})
    error_message = "stage_invoke_urls is empty."
  }
  assert {
    condition     = output.stage_execution_arns == tomap({})
    error_message = "stage_execution_arns is empty."
  }
  assert {
    condition     = output.integration_response_selection_expressions == tomap({})
    error_message = "integration_response_selection_expressions is empty."
  }
  assert {
    condition     = output.stage_tags_all == tomap({})
    error_message = "stage_tags_all is empty."
  }
  assert {
    condition     = output.domain_tags_all == tomap({})
    error_message = "domain_tags_all is empty."
  }
  assert {
    condition     = output.vpc_link_tags_all == tomap({})
    error_message = "vpc_link_tags_all is empty."
  }
}

run "null_maps" {
  command = plan
  variables {
    integrations          = null
    routes                = null
    stages                = null
    authorizers           = null
    domain_names          = null
    models                = null
    integration_responses = null
    route_responses       = null
    vpc_links             = null
    cors_configuration    = null
    jwt_configuration     = null
  }
  assert {
    condition     = output.integration_ids == tomap({})
    error_message = "integration_ids is empty."
  }
  assert {
    condition     = output.route_ids == tomap({})
    error_message = "route_ids is empty."
  }
  assert {
    condition     = output.stage_ids == tomap({})
    error_message = "stage_ids is empty."
  }
  assert {
    condition     = output.authorizer_ids == tomap({})
    error_message = "authorizer_ids is empty."
  }
  assert {
    condition     = output.domains == tomap({})
    error_message = "domains is empty."
  }
  assert {
    condition     = output.model_ids == tomap({})
    error_message = "model_ids is empty."
  }
  assert {
    condition     = output.integration_response_ids == tomap({})
    error_message = "integration_response_ids is empty."
  }
  assert {
    condition     = output.route_response_ids == tomap({})
    error_message = "route_response_ids is empty."
  }
  assert {
    condition     = output.vpc_link_ids == tomap({})
    error_message = "vpc_link_ids is empty."
  }
  assert {
    condition     = output.vpc_link_arns == tomap({})
    error_message = "vpc_link_arns is empty."
  }
  assert {
    condition     = output.stage_arns == tomap({})
    error_message = "stage_arns is empty."
  }
  assert {
    condition     = output.stage_invoke_urls == tomap({})
    error_message = "stage_invoke_urls is empty."
  }
  assert {
    condition     = output.stage_execution_arns == tomap({})
    error_message = "stage_execution_arns is empty."
  }
  assert {
    condition     = output.integration_response_selection_expressions == tomap({})
    error_message = "integration_response_selection_expressions is empty."
  }
  assert {
    condition     = output.stage_tags_all == tomap({})
    error_message = "stage_tags_all is empty."
  }
  assert {
    condition     = output.domain_tags_all == tomap({})
    error_message = "domain_tags_all is empty."
  }
  assert {
    condition     = output.vpc_link_tags_all == tomap({})
    error_message = "vpc_link_tags_all is empty."
  }
}

run "minimal_objects" {
  command = plan
  variables {
    integrations = {
      "one" = {
        "integration_type" = "HTTP_PROXY"
      }
      "two" = {
        "integration_type" = "HTTP_PROXY"
      }
    }
    routes = {
      "one" = {
        "route_key" = "GET /"
      }
    }
    stages = {
      "stage" = {
        "stage_name" = "ignored"
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_integration.this["one"].payload_format_version == "1.0" && aws_apigatewayv2_integration.this["one"].connection_type == "INTERNET" && !aws_apigatewayv2_stage.this["stage"].auto_deploy && aws_apigatewayv2_stage.this["stage"].name == "stage"
    error_message = "Provider defaults and keyed names are retained."
  }
  assert {
    condition     = length(aws_apigatewayv2_integration.this["one"].response_parameters) == 0 && length(aws_apigatewayv2_integration.this["one"].tls_config) == 0 && length(aws_apigatewayv2_route.this["one"].request_parameter) == 0 && length(aws_apigatewayv2_stage.this["stage"].access_log_settings) == 0 && length(aws_apigatewayv2_stage.this["stage"].default_route_settings) == 0 && length(aws_apigatewayv2_stage.this["stage"].route_settings) == 0
    error_message = "Optional blocks remain absent."
  }
  assert {
    condition     = aws_apigatewayv2_route.this["one"].target == null && aws_apigatewayv2_route.this["one"].authorizer_id == null && aws_apigatewayv2_integration.this["one"].connection_id == null
    error_message = "Optional literal or internal references allow neither."
  }
  assert {
    condition     = toset(keys(aws_apigatewayv2_integration.this)) == toset(["one", "two"])
    error_message = "Multiple integrations preserve keys."
  }
}

run "cors_empty_false_zero" {
  command = plan
  variables {
    cors_configuration = {
      "allow_credentials" = false
      "max_age"           = 0
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 0
    error_message = "Semantically empty CORS omits the block."
  }
}

run "cors_empty_null_lists" {
  command = plan
  variables {
    cors_configuration = {
      "allow_headers"  = null
      "allow_origins"  = null
      "allow_methods"  = null
      "expose_headers" = null
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 0
    error_message = "Semantically empty CORS omits the block."
  }
}

run "cors_empty_empty_lists" {
  command = plan
  variables {
    cors_configuration = {
      "allow_headers"  = []
      "allow_origins"  = []
      "allow_methods"  = []
      "expose_headers" = []
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 0
    error_message = "Semantically empty CORS omits the block."
  }
}

run "cors_set_credentials" {
  command = plan
  variables {
    cors_configuration = {
      "allow_credentials" = true
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 1
    error_message = "Meaningful CORS produces exactly one provider-shaped block."
  }
  assert {
    condition     = output.cors_configuration[0].allow_credentials == true
    error_message = "allow_credentials reaches the CORS block."
  }
}

run "cors_set_age" {
  command = plan
  variables {
    cors_configuration = {
      "max_age" = 60
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 1
    error_message = "Meaningful CORS produces exactly one provider-shaped block."
  }
  assert {
    condition     = output.cors_configuration[0].max_age == 60
    error_message = "max_age reaches the CORS block."
  }
}

run "cors_set_headers" {
  command = plan
  variables {
    cors_configuration = {
      "allow_headers" = ["x-fixture"]
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 1
    error_message = "Meaningful CORS produces exactly one provider-shaped block."
  }
  assert {
    condition     = output.cors_configuration[0].allow_headers == toset(["x-fixture"])
    error_message = "allow_headers reaches the CORS block."
  }
}

run "cors_set_origins" {
  command = plan
  variables {
    cors_configuration = {
      "allow_origins" = ["https://example.invalid"]
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 1
    error_message = "Meaningful CORS produces exactly one provider-shaped block."
  }
  assert {
    condition     = output.cors_configuration[0].allow_origins == toset(["https://example.invalid"])
    error_message = "allow_origins reaches the CORS block."
  }
}

run "cors_set_methods" {
  command = plan
  variables {
    cors_configuration = {
      "allow_methods" = ["POST"]
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 1
    error_message = "Meaningful CORS produces exactly one provider-shaped block."
  }
  assert {
    condition     = output.cors_configuration[0].allow_methods == toset(["POST"])
    error_message = "allow_methods reaches the CORS block."
  }
}

run "cors_set_expose" {
  command = plan
  variables {
    cors_configuration = {
      "expose_headers" = ["x-fixture"]
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 1
    error_message = "Meaningful CORS produces exactly one provider-shaped block."
  }
  assert {
    condition     = output.cors_configuration[0].expose_headers == toset(["x-fixture"])
    error_message = "expose_headers reaches the CORS block."
  }
}

run "openapi_import" {
  command = plan
  variables {
    body = "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
  }
  assert {
    condition     = aws_apigatewayv2_api.this.body == "{\"openapi\":\"3.0.1\",\"info\":{\"title\":\"fake\",\"version\":\"1\"},\"paths\":{}}"
    error_message = "OpenAPI body remains unchanged."
  }
  assert {
    condition     = length(aws_apigatewayv2_integration.this) == 0 && length(aws_apigatewayv2_route.this) == 0
    error_message = "No explicit ownership is synthesized."
  }
}

run "quick_create" {
  command = plan
  variables {
    target           = "arn:aws:lambda:us-east-1:123456789012:function:fake"
    route_key        = "POST /"
    credentials_arn  = "arn:aws:iam::123456789012:role/fake"
    fail_on_warnings = true
  }
  assert {
    condition     = aws_apigatewayv2_api.this.target == "arn:aws:lambda:us-east-1:123456789012:function:fake" && aws_apigatewayv2_api.this.route_key == "POST /" && aws_apigatewayv2_api.this.credentials_arn == "arn:aws:iam::123456789012:role/fake" && aws_apigatewayv2_api.this.fail_on_warnings && length(aws_apigatewayv2_stage.this) == 0
    error_message = "Quick-create values are forwarded without explicit children."
  }
}

run "http_advanced" {
  command = plan
  variables {
    region          = "us-west-2"
    ip_address_type = "dualstack"
    tags = {
      "Name" = "shared"
      "Team" = "platform"
    }
    integrations = {
      "advanced" = {
        "integration_type"              = "AWS_PROXY"
        "integration_subtype"           = "SQS-SendMessage"
        "integration_method"            = "POST"
        "credentials_arn"               = "arn:aws:iam::123456789012:role/fake"
        "description"                   = "advanced"
        "payload_format_version"        = "1.0"
        "template_selection_expression" = "$request.header.content-type"
        "request_parameters" = {
          "QueueUrl" = "https://sqs.us-west-2.amazonaws.com/123456789012/fake"
        }
        "response_parameters" = {
          "success" = {
            "status_code" = "200"
            "mappings" = {
              "append:header.x-fixture" = "ok"
            }
          }
        }
        "timeout_milliseconds" = 30000
      }
    }
    stages = {
      "stage" = {
        "description"   = "forwarded description"
        "stage_name"    = "ignored"
        "deployment_id" = "external-deployment"
        "stage_variables" = {
          "fixture" = "yes"
        }
        "tags" = {
          "Name"  = "stage-override"
          "Stage" = "test"
        }
        "default_route_settings" = {
          "data_trace_enabled"       = false
          "detailed_metrics_enabled" = true
          "throttling_burst_limit"   = 0
          "throttling_rate_limit"    = 0
        }
        "route_settings" = {
          "GET /" = {
            "detailed_metrics_enabled" = true
            "throttling_burst_limit"   = 10
            "throttling_rate_limit"    = 2.5
          }
        }
      }
    }
    routes = {
      "route" = {
        "route_key"            = "GET /"
        "target"               = "integrations/literal"
        "authorizer_id"        = "external-authorizer"
        "authorization_type"   = "JWT"
        "authorization_scopes" = ["read"]
        "operation_name"       = "Read"
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_integration.this["advanced"].integration_subtype == "SQS-SendMessage" && aws_apigatewayv2_integration.this["advanced"].template_selection_expression == "$request.header.content-type" && aws_apigatewayv2_integration.this["advanced"].request_parameters["QueueUrl"] == "https://sqs.us-west-2.amazonaws.com/123456789012/fake" && one(aws_apigatewayv2_integration.this["advanced"].response_parameters).status_code == "200" && one(aws_apigatewayv2_integration.this["advanced"].response_parameters).mappings["append:header.x-fixture"] == "ok" && aws_apigatewayv2_integration.this["advanced"].timeout_milliseconds == 30000
    error_message = "Integration optional arguments are wired."
  }
  assert {
    condition     = aws_apigatewayv2_stage.this["stage"].description == "forwarded description" && aws_apigatewayv2_stage.this["stage"].deployment_id == "external-deployment" && aws_apigatewayv2_stage.this["stage"].stage_variables["fixture"] == "yes" && aws_apigatewayv2_stage.this["stage"].default_route_settings[0].detailed_metrics_enabled && aws_apigatewayv2_stage.this["stage"].default_route_settings[0].throttling_burst_limit == 0 && aws_apigatewayv2_stage.this["stage"].default_route_settings[0].throttling_rate_limit == 0 && one(aws_apigatewayv2_stage.this["stage"].route_settings).route_key == "GET /" && one(aws_apigatewayv2_stage.this["stage"].route_settings).throttling_rate_limit == 2.5 && aws_apigatewayv2_stage.this["stage"].tags.Name == "stage-override"
    error_message = "Stage optional arguments and per-route keys are wired."
  }
  assert {
    condition     = aws_apigatewayv2_route.this["route"].target == "integrations/literal" && aws_apigatewayv2_route.this["route"].authorizer_id == "external-authorizer" && aws_apigatewayv2_route.this["route"].authorization_scopes == toset(["read"]) && aws_apigatewayv2_route.this["route"].operation_name == "Read"
    error_message = "Literal references remain unchanged."
  }
  assert {
    condition     = aws_apigatewayv2_api.this.region == "us-west-2" && aws_apigatewayv2_integration.this["advanced"].region == "us-west-2" && aws_apigatewayv2_route.this["route"].region == "us-west-2" && aws_apigatewayv2_stage.this["stage"].region == "us-west-2" && aws_apigatewayv2_api.this.tags.Name == "shared"
    error_message = "Common region and caller tag precedence are consistent."
  }
}

run "jwt_nested" {
  command = plan
  variables {
    jwt_configuration = {}
    authorizers = {
      "jwt" = {
        "authorizer_type" = "JWT"
        "name"            = "ignored"
        "jwt_configuration" = {
          "audience" = ["fixture"]
          "issuer"   = "https://issuer.invalid"
        }
        "identity_sources" = ["$request.header.Authorization"]
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["jwt"].name == "jwt" && aws_apigatewayv2_authorizer.this["jwt"].jwt_configuration[0].audience == toset(["fixture"]) && aws_apigatewayv2_authorizer.this["jwt"].jwt_configuration[0].issuer == "https://issuer.invalid"
    error_message = "JWT nested or fallback values are exact."
  }
}

run "jwt_global" {
  command = plan
  variables {
    jwt_configuration = {
      "audience" = ["fixture"]
      "issuer"   = "https://issuer.invalid"
    }
    authorizers = {
      "jwt" = {
        "authorizer_type"   = "JWT"
        "name"              = "ignored"
        "jwt_configuration" = null
        "identity_sources"  = ["$request.header.Authorization"]
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["jwt"].name == "jwt" && aws_apigatewayv2_authorizer.this["jwt"].jwt_configuration[0].audience == toset(["fixture"]) && aws_apigatewayv2_authorizer.this["jwt"].jwt_configuration[0].issuer == "https://issuer.invalid"
    error_message = "JWT nested or fallback values are exact."
  }
}

run "jwt_equal" {
  command = plan
  variables {
    jwt_configuration = {
      "audience" = ["fixture"]
      "issuer"   = "https://issuer.invalid"
    }
    authorizers = {
      "jwt" = {
        "authorizer_type" = "JWT"
        "name"            = "ignored"
        "jwt_configuration" = {
          "audience" = ["fixture"]
          "issuer"   = "https://issuer.invalid"
        }
        "identity_sources" = ["$request.header.Authorization"]
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["jwt"].name == "jwt" && aws_apigatewayv2_authorizer.this["jwt"].jwt_configuration[0].audience == toset(["fixture"]) && aws_apigatewayv2_authorizer.this["jwt"].jwt_configuration[0].issuer == "https://issuer.invalid"
    error_message = "JWT nested or fallback values are exact."
  }
}

run "request_legacy_zero" {
  command = plan
  variables {
    jwt_configuration = {
      "audience" = ["fixture"]
      "issuer"   = "https://issuer.invalid"
    }
    authorizers = {
      "request" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_uri"                    = "arn:aws:lambda:us-east-1:123456789012:function:fake"
        "authorizer_payload_format_version" = "2.0"
        "enable_simple_responses"           = true
        "identity_sources"                  = ["$request.header.Authorization"]
        "provider_arns"                     = ["ignored"]
        "scopes"                            = ["ignored"]
        "token_validation_expression"       = "ignored"
        "timeouts" = {
          "delete" = "5m"
        }
        "authorizer_result_ttl" = 0
      }
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_authorizer.this["request"].jwt_configuration) == 0 && aws_apigatewayv2_authorizer.this["request"].authorizer_result_ttl_in_seconds == 0
    error_message = "REQUEST never emits global JWT and TTL forwards exactly."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["request"].enable_simple_responses && aws_apigatewayv2_authorizer.this["request"].timeouts.delete == "5m"
    error_message = "REQUEST settings and timeout are forwarded."
  }
}

run "request_canonical_zero" {
  command = plan
  variables {
    jwt_configuration = {
      "audience" = ["fixture"]
      "issuer"   = "https://issuer.invalid"
    }
    authorizers = {
      "request" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_uri"                    = "arn:aws:lambda:us-east-1:123456789012:function:fake"
        "authorizer_payload_format_version" = "2.0"
        "enable_simple_responses"           = true
        "identity_sources"                  = ["$request.header.Authorization"]
        "provider_arns"                     = ["ignored"]
        "scopes"                            = ["ignored"]
        "token_validation_expression"       = "ignored"
        "timeouts" = {
          "delete" = "5m"
        }
        "authorizer_result_ttl_in_seconds" = 0
      }
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_authorizer.this["request"].jwt_configuration) == 0 && aws_apigatewayv2_authorizer.this["request"].authorizer_result_ttl_in_seconds == 0
    error_message = "REQUEST never emits global JWT and TTL forwards exactly."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["request"].enable_simple_responses && aws_apigatewayv2_authorizer.this["request"].timeouts.delete == "5m"
    error_message = "REQUEST settings and timeout are forwarded."
  }
}

run "request_equal_zero" {
  command = plan
  variables {
    jwt_configuration = {
      "audience" = ["fixture"]
      "issuer"   = "https://issuer.invalid"
    }
    authorizers = {
      "request" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_uri"                    = "arn:aws:lambda:us-east-1:123456789012:function:fake"
        "authorizer_payload_format_version" = "2.0"
        "enable_simple_responses"           = true
        "identity_sources"                  = ["$request.header.Authorization"]
        "provider_arns"                     = ["ignored"]
        "scopes"                            = ["ignored"]
        "token_validation_expression"       = "ignored"
        "timeouts" = {
          "delete" = "5m"
        }
        "authorizer_result_ttl"            = 0
        "authorizer_result_ttl_in_seconds" = 0
      }
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_authorizer.this["request"].jwt_configuration) == 0 && aws_apigatewayv2_authorizer.this["request"].authorizer_result_ttl_in_seconds == 0
    error_message = "REQUEST never emits global JWT and TTL forwards exactly."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["request"].enable_simple_responses && aws_apigatewayv2_authorizer.this["request"].timeouts.delete == "5m"
    error_message = "REQUEST settings and timeout are forwarded."
  }
}

run "request_upper" {
  command = plan
  variables {
    jwt_configuration = {
      "audience" = ["fixture"]
      "issuer"   = "https://issuer.invalid"
    }
    authorizers = {
      "request" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_uri"                    = "arn:aws:lambda:us-east-1:123456789012:function:fake"
        "authorizer_payload_format_version" = "2.0"
        "enable_simple_responses"           = true
        "identity_sources"                  = ["$request.header.Authorization"]
        "provider_arns"                     = ["ignored"]
        "scopes"                            = ["ignored"]
        "token_validation_expression"       = "ignored"
        "timeouts" = {
          "delete" = "5m"
        }
        "authorizer_result_ttl_in_seconds" = 3600
      }
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_authorizer.this["request"].jwt_configuration) == 0 && aws_apigatewayv2_authorizer.this["request"].authorizer_result_ttl_in_seconds == 3600
    error_message = "REQUEST never emits global JWT and TTL forwards exactly."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["request"].enable_simple_responses && aws_apigatewayv2_authorizer.this["request"].timeouts.delete == "5m"
    error_message = "REQUEST settings and timeout are forwarded."
  }
}

run "domain_absent" {
  command = plan
  variables {
    region                    = "us-west-2"
    mutual_tls_authentication = null
    domain_names = {
      "api.example.invalid" = {
        "domain_name_configuration" = {
          "certificate_arn"                        = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
          "ip_address_type"                        = "dualstack"
          "ownership_verification_certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "routing_mode"              = "API_MAPPING_ONLY"
        "mutual_tls_authentication" = null
        "timeouts" = {
          "create" = "11m"
          "update" = "61m"
        }
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/fake" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].endpoint_type == "REGIONAL" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].security_policy == "TLS_1_2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].ip_address_type == "dualstack" && aws_apigatewayv2_domain_name.this["api.example.invalid"].routing_mode == "API_MAPPING_ONLY"
    error_message = "Domain configuration uses declared nested fields."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].region == "us-west-2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.create == "11m" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.update == "61m"
    error_message = "Domain region and timeouts are exact."
  }
  assert {
    condition     = length(aws_apigatewayv2_domain_name.this["api.example.invalid"].mutual_tls_authentication) == 0
    error_message = "Mutual TLS is omitted or forwarded exactly."
  }
}

run "domain_nested" {
  command = plan
  variables {
    region                    = "us-west-2"
    mutual_tls_authentication = null
    domain_names = {
      "api.example.invalid" = {
        "domain_name_configuration" = {
          "certificate_arn"                        = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
          "ip_address_type"                        = "dualstack"
          "ownership_verification_certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "routing_mode" = "API_MAPPING_ONLY"
        "mutual_tls_authentication" = {
          "truststore_uri"     = "s3://fake-bucket/trust.pem"
          "truststore_version" = "1"
        }
        "timeouts" = {
          "create" = "11m"
          "update" = "61m"
        }
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/fake" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].endpoint_type == "REGIONAL" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].security_policy == "TLS_1_2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].ip_address_type == "dualstack" && aws_apigatewayv2_domain_name.this["api.example.invalid"].routing_mode == "API_MAPPING_ONLY"
    error_message = "Domain configuration uses declared nested fields."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].region == "us-west-2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.create == "11m" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.update == "61m"
    error_message = "Domain region and timeouts are exact."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].mutual_tls_authentication[0].truststore_uri == "s3://fake-bucket/trust.pem" && aws_apigatewayv2_domain_name.this["api.example.invalid"].mutual_tls_authentication[0].truststore_version == "1"
    error_message = "Mutual TLS is omitted or forwarded exactly."
  }
}

run "domain_global" {
  command = plan
  variables {
    region = "us-west-2"
    mutual_tls_authentication = {
      "truststore_uri"     = "s3://fake-bucket/trust.pem"
      "truststore_version" = "1"
    }
    domain_names = {
      "api.example.invalid" = {
        "domain_name_configuration" = {
          "certificate_arn"                        = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
          "ip_address_type"                        = "dualstack"
          "ownership_verification_certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "routing_mode"              = "API_MAPPING_ONLY"
        "mutual_tls_authentication" = null
        "timeouts" = {
          "create" = "11m"
          "update" = "61m"
        }
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/fake" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].endpoint_type == "REGIONAL" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].security_policy == "TLS_1_2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].ip_address_type == "dualstack" && aws_apigatewayv2_domain_name.this["api.example.invalid"].routing_mode == "API_MAPPING_ONLY"
    error_message = "Domain configuration uses declared nested fields."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].region == "us-west-2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.create == "11m" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.update == "61m"
    error_message = "Domain region and timeouts are exact."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].mutual_tls_authentication[0].truststore_uri == "s3://fake-bucket/trust.pem" && aws_apigatewayv2_domain_name.this["api.example.invalid"].mutual_tls_authentication[0].truststore_version == "1"
    error_message = "Mutual TLS is omitted or forwarded exactly."
  }
}

run "domain_equal" {
  command = plan
  variables {
    region = "us-west-2"
    mutual_tls_authentication = {
      "truststore_uri"     = "s3://fake-bucket/trust.pem"
      "truststore_version" = "1"
    }
    domain_names = {
      "api.example.invalid" = {
        "domain_name_configuration" = {
          "certificate_arn"                        = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
          "ip_address_type"                        = "dualstack"
          "ownership_verification_certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "routing_mode" = "API_MAPPING_ONLY"
        "mutual_tls_authentication" = {
          "truststore_uri"     = "s3://fake-bucket/trust.pem"
          "truststore_version" = "1"
        }
        "timeouts" = {
          "create" = "11m"
          "update" = "61m"
        }
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/fake" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].endpoint_type == "REGIONAL" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].security_policy == "TLS_1_2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].ip_address_type == "dualstack" && aws_apigatewayv2_domain_name.this["api.example.invalid"].routing_mode == "API_MAPPING_ONLY"
    error_message = "Domain configuration uses declared nested fields."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].region == "us-west-2" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.create == "11m" && aws_apigatewayv2_domain_name.this["api.example.invalid"].timeouts.update == "61m"
    error_message = "Domain region and timeouts are exact."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].mutual_tls_authentication[0].truststore_uri == "s3://fake-bucket/trust.pem" && aws_apigatewayv2_domain_name.this["api.example.invalid"].mutual_tls_authentication[0].truststore_version == "1"
    error_message = "Mutual TLS is omitted or forwarded exactly."
  }
}

run "domain_routing_rule_only" {
  command = plan
  variables {
    domain_names = {
      "api.example.invalid" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "routing_mode" = "ROUTING_RULE_ONLY"
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].routing_mode == "ROUTING_RULE_ONLY"
    error_message = "Routing mode forwards exactly."
  }
}

run "domain_routing_rule_then_api_mapping" {
  command = plan
  variables {
    domain_names = {
      "api.example.invalid" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
        "routing_mode" = "ROUTING_RULE_THEN_API_MAPPING"
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].routing_mode == "ROUTING_RULE_THEN_API_MAPPING"
    error_message = "Routing mode forwards exactly."
  }
}

run "boundaries" {
  command = plan
  variables {
    description = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    api_version = "vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv"
    integrations = {
      "lower" = {
        "integration_type"       = "HTTP_PROXY"
        "timeout_milliseconds"   = 50
        "payload_format_version" = "1.0"
        "response_parameters" = {
          "last" = {
            "status_code" = "599"
            "mappings" = {
              "append:header.x" = "last"
            }
          }
        }
      }
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_api.this.description) == 1024 && length(aws_apigatewayv2_api.this.version) == 64 && aws_apigatewayv2_integration.this["lower"].timeout_milliseconds == 50 && one(aws_apigatewayv2_integration.this["lower"].response_parameters).status_code == "599"
    error_message = "Valid description/version/timeout/status boundaries are accepted."
  }
}

run "websocket_full" {
  command = apply
  variables {
    protocol_type              = "WEBSOCKET"
    region                     = "us-west-2"
    route_selection_expression = "$request.body.action"
    vpc_links = {
      "private" = {
        "security_group_ids" = ["sg-12345678"]
        "subnet_ids"         = ["subnet-12345678"]
        "tags" = {
          "Name" = "private-override"
          "Link" = "yes"
        }
      }
    }
    integrations = {
      "socket" = {
        "integration_type"          = "AWS"
        "connection_type"           = "INTERNET"
        "integration_method"        = "POST"
        "integration_uri"           = "arn:aws:lambda:us-east-1:123456789012:function:fake"
        "content_handling_strategy" = "CONVERT_TO_BINARY"
        "passthrough_behavior"      = "NEVER"
        "request_templates" = {
          "application/json" = "{}"
        }
        "request_parameters" = {
          "integration.request.header.x" = "context.requestId"
        }
        "timeout_milliseconds" = 29000
      }
    }
    authorizers = {
      "socket" = {
        "authorizer_type"            = "REQUEST"
        "authorizer_credentials_arn" = "arn:aws:iam::123456789012:role/fake"
        "authorizer_uri"             = "arn:aws:lambda:us-east-1:123456789012:function:fake"
        "name"                       = "ignored"
      }
    }
    models = {
      "Message" = {
        "name"         = "IgnoredName"
        "content_type" = "application/json"
        "schema"       = "{\"type\":\"object\"}"
        "description"  = "A message"
      }
    }
    routes = {
      "logical" = {
        "route_key"          = "$connect"
        "integration_key"    = "socket"
        "authorizer_key"     = "socket"
        "authorization_type" = "CUSTOM"
        "api_key_required"   = true
        "request_models" = {
          "application/json" = "Message"
        }
        "model_selection_expression"          = "$request.body.model"
        "route_response_selection_expression" = "$default"
        "request_parameter" = {
          "x" = {
            "request_parameter_key" = "route.request.querystring.x"
            "required"              = true
          }
        }
      }
      "legacy" = {
        "route_key" = "$disconnect"
        "target"    = "integrations/literal"
        "request_parameters" = {
          "route.request.querystring.x" = "false"
          "route.request.querystring.y" = "true"
        }
      }
    }
    integration_responses = {
      "internal" = {
        "integration_key"           = "socket"
        "integration_response_key"  = "$default"
        "content_handling_strategy" = "CONVERT_TO_TEXT"
        "response_templates" = {
          "application/json" = "{}"
        }
        "template_selection_expression" = "$default"
      }
      "literal" = {
        "integration_id"           = "literal-int"
        "integration_response_key" = "/2\\d\\d/"
      }
    }
    route_responses = {
      "internal" = {
        "route_key"          = "logical"
        "route_response_key" = "$default"
        "response_models" = {
          "application/json" = "Message"
        }
        "model_selection_expression" = "$default"
      }
      "literal" = {
        "route_id"           = "literal-route"
        "route_response_key" = "$default"
      }
    }
    stages = {
      "socket" = {
        "stage_name"            = "ignored"
        "client_certificate_id" = "external-cert"
        "description"           = "socket stage"
        "default_route_settings" = {
          "data_trace_enabled"       = true
          "logging_level"            = "ERROR"
          "detailed_metrics_enabled" = true
          "throttling_burst_limit"   = 20
          "throttling_rate_limit"    = 10
        }
        "route_settings" = {
          "$connect" = {
            "data_trace_enabled"       = true
            "logging_level"            = "INFO"
            "detailed_metrics_enabled" = true
            "throttling_burst_limit"   = 10
            "throttling_rate_limit"    = 2
          }
        }
        "tags" = {
          "Name" = "socket-override"
        }
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_vpc_link.this["private"].tags.Name == "private-override" && aws_apigatewayv2_vpc_link.this["private"].region == "us-west-2"
    error_message = "VPC-link caller tags and region are forwarded."
  }
  assert {
    condition     = aws_apigatewayv2_route.this["logical"].target == "integrations/int123" && aws_apigatewayv2_route.this["logical"].authorizer_id == "auth123"
    error_message = "Internal integration and authorizer IDs flow into the logical route."
  }
  assert {
    condition     = aws_apigatewayv2_route_response.this["internal"].route_id == "route123" && aws_apigatewayv2_route_response.this["literal"].route_id == "literal-route" && aws_apigatewayv2_integration_response.this["internal"].integration_id == "int123" && aws_apigatewayv2_integration_response.this["literal"].integration_id == "literal-int"
    error_message = "Response parent IDs resolve logical keys, not route strings."
  }
  assert {
    condition     = one(aws_apigatewayv2_route.this["logical"].request_parameter).request_parameter_key == "route.request.querystring.x" && one(aws_apigatewayv2_route.this["logical"].request_parameter).required
    error_message = "Singular route parameters preserve boolean values."
  }
  assert {
    condition     = tomap({ for p in aws_apigatewayv2_route.this["legacy"].request_parameter : p.request_parameter_key => p.required }) == tomap({ "route.request.querystring.x" = false, "route.request.querystring.y" = true })
    error_message = "Legacy boolean strings convert to precise provider blocks."
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["socket"].name == "socket" && aws_apigatewayv2_model.this["Message"].name == "Message" && aws_apigatewayv2_stage.this["socket"].name == "socket"
    error_message = "Legacy aliases never rename resources."
  }
  assert {
    condition     = aws_apigatewayv2_stage.this["socket"].client_certificate_id == "external-cert" && aws_apigatewayv2_stage.this["socket"].default_route_settings[0].logging_level == "ERROR" && aws_apigatewayv2_stage.this["socket"].default_route_settings[0].data_trace_enabled && one(aws_apigatewayv2_stage.this["socket"].route_settings).logging_level == "INFO" && one(aws_apigatewayv2_stage.this["socket"].route_settings).route_key == "$connect"
    error_message = "WebSocket stage settings and certificate are forwarded."
  }
  assert {
    condition     = jsondecode(aws_apigatewayv2_model.this["Message"].schema).type == "object" && aws_apigatewayv2_integration_response.this["internal"].response_templates["application/json"] == "{}" && aws_apigatewayv2_integration_response.this["internal"].template_selection_expression == "$default" && aws_apigatewayv2_route_response.this["internal"].response_models["application/json"] == "Message"
    error_message = "Model and response options reach resources."
  }
  assert {
    condition     = output.authorizer_ids == tomap({ "socket" = "auth123" })
    error_message = "Exact authorizer_ids map."
  }
  assert {
    condition     = output.model_ids == tomap({ "Message" = "model123" })
    error_message = "Exact model_ids map."
  }
  assert {
    condition     = output.integration_response_ids == tomap({ "internal" = "ir123", "literal" = "ir123" })
    error_message = "Exact integration_response_ids map."
  }
  assert {
    condition     = output.route_response_ids == tomap({ "internal" = "rr123", "literal" = "rr123" })
    error_message = "Exact route_response_ids map."
  }
  assert {
    condition     = output.vpc_link_ids == tomap({ "private" = "vpc123" })
    error_message = "Exact vpc_link_ids map."
  }
  assert {
    condition     = output.vpc_link_arns == tomap({ "private" = "arn:aws:apigateway:us-east-1::/vpclinks/vpc123" })
    error_message = "Exact vpc_link_arns map."
  }
  assert {
    condition     = output.vpc_link_tags_all == tomap({ "private" = tomap({ "Name" = "link", "fixture" = "true" }) })
    error_message = "Exact vpc_link_tags_all map."
  }
}

run "http_private_wiring" {
  command = apply
  variables {
    region = "us-west-2"
    vpc_links = {
      "private" = {
        "security_group_ids" = ["sg-12345678"]
        "subnet_ids"         = ["subnet-12345678"]
      }
    }
    integrations = {
      "internal" = {
        "integration_type"   = "HTTP_PROXY"
        "integration_method" = "ANY"
        "connection_type"    = "VPC_LINK"
        "vpc_link_key"       = "private"
        "tls_config" = {
          "server_name_to_verify" = "example.invalid"
        }
      }
      "external" = {
        "integration_type" = "HTTP_PROXY"
        "connection_type"  = "VPC_LINK"
        "connection_id"    = "external-vpc"
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_integration.this["internal"].connection_id == "vpc123" && aws_apigatewayv2_integration.this["internal"].connection_type == "VPC_LINK"
    error_message = "Internal VPC-link ID reaches the integration exactly."
  }
  assert {
    condition     = aws_apigatewayv2_integration.this["external"].connection_id == "external-vpc"
    error_message = "Literal connection IDs are preserved."
  }
  assert {
    condition     = aws_apigatewayv2_integration.this["internal"].tls_config[0].server_name_to_verify == "example.invalid"
    error_message = "Private HTTP TLS server name reaches the provider exactly."
  }
}

run "domain_outputs" {
  command = apply
  variables {
    domain_names = {
      "api.example.invalid" = {
        "domain_name_configuration" = {
          "certificate_arn" = "arn:aws:acm:us-east-1:123456789012:certificate/fake"
        }
      }
    }
  }
  assert {
    condition     = output.domains == tomap({ "api.example.invalid" = { id = "api.example.invalid", arn = "arn:aws:apigateway:us-east-1::/domainnames/api.example.invalid", target_domain_name = "d-fake.execute-api.us-east-1.amazonaws.com", hosted_zone_id = "ZFAKE", api_mapping_selection_expression = "$request.basepath" } })
    error_message = "Every domain output field has an exact deterministic value."
  }
  assert {
    condition     = output.domain_tags_all == tomap({ "api.example.invalid" = tomap({ "Name" = "api.example.invalid", "fixture" = "true" }) })
    error_message = "Domain tags_all retains its original key and exact metadata."
  }
  assert {
    condition     = aws_apigatewayv2_domain_name.this["api.example.invalid"].domain_name_configuration[0].certificate_arn == "arn:aws:acm:us-east-1:123456789012:certificate/fake"
    error_message = "Computed nested defaults do not replace configured certificate values."
  }
}

run "websocket_other_enums" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    integrations = {
      "mock" = {
        "integration_type"     = "MOCK"
        "passthrough_behavior" = "WHEN_NO_TEMPLATES"
      }
      "http" = {
        "integration_type"          = "HTTP"
        "integration_method"        = "POST"
        "content_handling_strategy" = "CONVERT_TO_TEXT"
        "passthrough_behavior"      = "WHEN_NO_MATCH"
        "request_templates" = {
          "application/json" = "{}"
        }
      }
    }
    stages = {
      "quiet" = {
        "default_route_settings" = {
          "logging_level"      = "OFF"
          "data_trace_enabled" = false

          "throttling_burst_limit" = 10
          "throttling_rate_limit"  = 10
        }
        "route_settings" = {
          "$default" = {
            "logging_level"      = "OFF"
            "data_trace_enabled" = false

            "throttling_burst_limit" = 10
            "throttling_rate_limit"  = 10
          }
        }
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_integration.this["mock"].passthrough_behavior == "WHEN_NO_TEMPLATES" && aws_apigatewayv2_integration.this["http"].passthrough_behavior == "WHEN_NO_MATCH" && aws_apigatewayv2_integration.this["http"].content_handling_strategy == "CONVERT_TO_TEXT" && aws_apigatewayv2_integration.this["http"].request_templates["application/json"] == "{}"
    error_message = "WebSocket templates, passthrough and content conversion are exact."
  }
  assert {
    condition     = aws_apigatewayv2_stage.this["quiet"].default_route_settings[0].logging_level == "OFF" && one(aws_apigatewayv2_stage.this["quiet"].route_settings).logging_level == "OFF" && !aws_apigatewayv2_stage.this["quiet"].default_route_settings[0].data_trace_enabled
    error_message = "WebSocket logging can be explicitly disabled."
  }
}

run "request_payload_v1" {
  command = plan
  variables {
    authorizers = {
      "request" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "1.0"
        "enable_simple_responses"           = false
        "authorizer_result_ttl_in_seconds"  = 1
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_authorizer.this["request"].authorizer_payload_format_version == "1.0" && !aws_apigatewayv2_authorizer.this["request"].enable_simple_responses && aws_apigatewayv2_authorizer.this["request"].authorizer_result_ttl_in_seconds == 1
    error_message = "HTTP REQUEST payload 1.0 remains supported without simple responses."
  }
}

run "websocket_empty_cors" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    cors_configuration = {
      "allow_credentials" = false
      "max_age"           = 0
    }
  }
  assert {
    condition     = length(output.cors_configuration) == 0
    error_message = "False/zero-only CORS does not create a false WebSocket conflict."
  }
}

run "version_one_ipv4" {
  command = plan
  variables {
    api_version     = "1"
    description     = ""
    ip_address_type = "ipv4"
  }
  assert {
    condition     = aws_apigatewayv2_api.this.version == "1" && aws_apigatewayv2_api.this.description == "" && aws_apigatewayv2_api.this.ip_address_type == "ipv4"
    error_message = "Shortest API version and empty description are valid."
  }
}

run "iam_http" {
  command = plan
  variables {
    protocol_type = "HTTP"
    routes = {
      "iam" = {
        "route_key"          = "GET /"
        "authorization_type" = "AWS_IAM"
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_route.this["iam"].authorization_type == "AWS_IAM"
    error_message = "IAM authorization is retained exactly on either protocol."
  }
}

run "iam_websocket" {
  command = plan
  variables {
    protocol_type = "WEBSOCKET"
    routes = {
      "iam" = {
        "route_key"          = "$connect"
        "authorization_type" = "AWS_IAM"
      }
    }
  }
  assert {
    condition     = aws_apigatewayv2_route.this["iam"].authorization_type == "AWS_IAM"
    error_message = "IAM authorization is retained exactly on either protocol."
  }
}

run "explicit_null_options" {
  command = plan
  variables {
    fail_on_warnings             = null
    disable_execute_api_endpoint = null
    jwt_configuration            = null
    integrations = {
      "minimal" = {
        "integration_type"    = "HTTP_PROXY"
        "response_parameters" = null
        "request_parameters"  = null
        "request_templates"   = null
        "tls_config"          = null
      }
    }
    routes = {
      "minimal" = {
        "route_key"          = "GET /"
        "request_parameter"  = null
        "request_parameters" = null
      }
    }
    stages = {
      "minimal" = {
        "access_log_settings"    = null
        "default_route_settings" = null
        "route_settings"         = null
        "tags"                   = null
      }
    }
    authorizers = {
      "minimal" = {
        "authorizer_type"                   = "REQUEST"
        "authorizer_payload_format_version" = "2.0"
        "timeouts"                          = null
      }
    }
  }
  assert {
    condition     = length(aws_apigatewayv2_integration.this["minimal"].response_parameters) == 0 && length(aws_apigatewayv2_integration.this["minimal"].tls_config) == 0 && length(aws_apigatewayv2_route.this["minimal"].request_parameter) == 0 && length(aws_apigatewayv2_stage.this["minimal"].route_settings) == 0 && length(aws_apigatewayv2_stage.this["minimal"].access_log_settings) == 0 && length(aws_apigatewayv2_authorizer.this["minimal"].jwt_configuration) == 0
    error_message = "Explicit null optional blocks remain absent."
  }
}

run "websocket_null_warnings" {
  command = plan
  variables {
    protocol_type    = "WEBSOCKET"
    fail_on_warnings = null
  }
  assert {
    condition     = aws_apigatewayv2_api.this.protocol_type == "WEBSOCKET"
    error_message = "Null legacy booleans do not preempt compatibility diagnostics."
  }
}
