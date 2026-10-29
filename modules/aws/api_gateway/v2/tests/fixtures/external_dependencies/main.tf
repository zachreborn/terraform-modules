terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

module "http" {
  source        = "../../.."
  name          = "external-dependencies"
  protocol_type = "HTTP"
  integrations = {
    dependent = {
      integration_type = "HTTP_PROXY"
      integration_uri  = "https://example.invalid/${module.http.id}"
    }
  }
  routes = {
    dependent = {
      route_key = "GET /"
      target    = "integrations/${aws_apigatewayv2_integration.external.id}"
    }
  }
  stages = {
    manual = {
      deployment_id = aws_apigatewayv2_deployment.external.id
    }
  }
}

resource "aws_apigatewayv2_integration" "external" {
  api_id           = module.http.id
  integration_type = "HTTP_PROXY"
  integration_uri  = "https://example.invalid"
}

resource "aws_apigatewayv2_deployment" "external" {
  api_id = module.http.id
}

output "wiring" {
  value = {
    api_id         = module.http.id
    integration_id = aws_apigatewayv2_integration.external.id
    deployment_id  = aws_apigatewayv2_deployment.external.id
    stage_id       = module.http.stage_ids["manual"]
  }
}
