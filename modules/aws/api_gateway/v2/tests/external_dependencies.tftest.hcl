mock_provider "aws" {
  mock_resource "aws_apigatewayv2_api" {
    defaults = { id = "external-api" }
  }
  mock_resource "aws_apigatewayv2_integration" {
    defaults = { id = "external-integration" }
  }
  mock_resource "aws_apigatewayv2_deployment" {
    defaults = { id = "external-deployment" }
  }
  mock_resource "aws_apigatewayv2_stage" {
    defaults = { id = "external-stage" }
  }
}

run "external_children_can_depend_on_api_output" {
  command = apply
  module {
    source = "./tests/fixtures/external_dependencies"
  }
  assert {
    condition = output.wiring == {
      api_id         = "external-api"
      integration_id = "external-integration"
      deployment_id  = "external-deployment"
      stage_id       = "external-stage"
    }
    error_message = "External deployment and child inputs must depend on the API without a cycle."
  }
}
