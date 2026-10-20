mock_provider "aws" {
  mock_resource "aws_api_gateway_rest_api" {
    defaults = {
      id               = "mock-rest-api-id"
      root_resource_id = "mock-root-resource-id"
      execution_arn    = "arn:aws:execute-api:us-east-1:123456789012:mock-rest-api-id"
      created_date     = "2026-01-01T00:00:00Z"
    }
  }

  mock_resource "aws_api_gateway_resource" {
    defaults = {
      id = "mock-resource-id"
    }
  }

  mock_resource "aws_api_gateway_method" {
    defaults = {
      id = "mock-method-id"
    }
  }

  mock_resource "aws_api_gateway_integration" {
    defaults = {
      id = "mock-integration-id"
    }
  }

  mock_resource "aws_api_gateway_deployment" {
    defaults = {
      id = "mock-deployment-id"
    }
  }

  mock_resource "aws_api_gateway_stage" {
    defaults = {
      id            = "mock-stage-id"
      arn           = "arn:aws:apigateway:us-east-1::/restapis/mock-rest-api-id/stages/prod"
      invoke_url    = "https://mock-rest-api-id.execute-api.us-east-1.amazonaws.com/prod"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:mock-rest-api-id/prod"
    }
  }
}

run "plan_succeeds_with_root_only_resources" {
  command = plan

  variables {
    name       = "example-api"
    stage_name = "prod"

    resources = {
      items = {
        path_part = "items"
      }
    }

    methods = {
      get_items = {
        resource      = "items"
        http_method   = "GET"
        authorization = "NONE"
      }
    }

    integrations = {
      get_items_mock = {
        resource = "items"
        method   = "get_items"
        type     = "MOCK"
        uri      = ""
        request_templates = {
          "application/json" = "{\"statusCode\": 200}"
        }
      }
    }
  }

  assert {
    condition     = length(aws_api_gateway_resource.this) == 1
    error_message = "Expected exactly one API Gateway resource."
  }

  assert {
    condition     = aws_api_gateway_resource.this["items"].parent_id == aws_api_gateway_rest_api.this.root_resource_id
    error_message = "Root-only resources must parent under the REST API root resource."
  }

  assert {
    condition     = aws_api_gateway_resource.this["items"].path_part == "items"
    error_message = "path_part should pass through unchanged."
  }
}

run "plan_succeeds_with_nested_resources" {
  command = plan

  variables {
    name       = "lead-api"
    stage_name = "prod"

    resources = {
      v1 = {
        path_part = "v1"
      }
      leads = {
        path_part           = "leads"
        parent_resource_key = "v1"
      }
    }

    methods = {
      post_leads = {
        resource      = "leads"
        http_method   = "POST"
        authorization = "NONE"
      }
      options_leads = {
        resource      = "leads"
        http_method   = "OPTIONS"
        authorization = "NONE"
      }
    }

    integrations = {
      post_leads_mock = {
        resource = "leads"
        method   = "post_leads"
        type     = "MOCK"
        uri      = ""
        request_templates = {
          "application/json" = "{\"statusCode\": 200}"
        }
      }
      options_leads_mock = {
        resource = "leads"
        method   = "options_leads"
        type     = "MOCK"
        uri      = ""
        request_templates = {
          "application/json" = "{\"statusCode\": 200}"
        }
      }
    }
  }

  assert {
    condition     = length(aws_api_gateway_resource.this) == 1 && length(aws_api_gateway_resource.nested) == 1
    error_message = "Expected v1 as root resource and leads as nested resource."
  }

  assert {
    condition     = aws_api_gateway_resource.this["v1"].parent_id == aws_api_gateway_rest_api.this.root_resource_id
    error_message = "v1 must parent under the REST API root resource."
  }

  assert {
    condition     = aws_api_gateway_resource.nested["leads"].parent_id == aws_api_gateway_resource.this["v1"].id
    error_message = "leads must parent under the v1 resource via parent_resource_key."
  }

  assert {
    condition     = aws_api_gateway_resource.nested["leads"].path_part == "leads"
    error_message = "Nested resource path_part should pass through unchanged."
  }

  assert {
    condition     = aws_api_gateway_method.this["post_leads"].resource_id == aws_api_gateway_resource.nested["leads"].id
    error_message = "Methods on nested resources must target the nested resource id."
  }

  assert {
    condition     = aws_api_gateway_integration.this["post_leads_mock"].resource_id == aws_api_gateway_resource.nested["leads"].id
    error_message = "Integrations on nested resources must target the nested resource id."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
