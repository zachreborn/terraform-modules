mock_provider "aws" {
  mock_resource "aws_api_gateway_rest_api" {
    defaults = {
      id               = "mock-rest-api-id"
      root_resource_id = "mock-root-resource-id"
      execution_arn    = "arn:aws:execute-api:us-east-1:123456789012:mock-rest-api-id"
      created_date     = "2026-01-01T00:00:00Z"
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

# Shared baseline: a custom domain with a regional ACM certificate. Individual runs override
# enable_mtls, bucket_name, and mtls_config.
variables {
  name            = "secure-api"
  stage_name      = "prod"
  domain_name     = "api.example.com"
  certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/00000000-0000-0000-0000-000000000000"
}

run "mtls_disabled_ignores_bucket_name" {
  command = plan

  variables {
    bucket_name = "my-truststore-bucket"
  }

  assert {
    condition     = length(aws_api_gateway_domain_name.this) == 1
    error_message = "The custom domain should be created when domain_name is set."
  }

  assert {
    condition     = length(aws_api_gateway_domain_name.this[0].mutual_tls_authentication) == 0
    error_message = "No mutual_tls_authentication block should be rendered when enable_mtls is false."
  }

  assert {
    condition     = output.mtls_enabled == false
    error_message = "mtls_enabled should be false by default."
  }

  assert {
    condition     = output.truststore_uri == null
    error_message = "truststore_uri output should be null when mTLS is disabled, even if bucket_name is set."
  }
}

run "mtls_builds_truststore_uri_from_bucket_name_with_default_key" {
  command = plan

  variables {
    enable_mtls = true
    bucket_name = "my-truststore-bucket"
  }

  assert {
    condition     = aws_api_gateway_domain_name.this[0].mutual_tls_authentication[0].truststore_uri == "s3://my-truststore-bucket/truststore.pem"
    error_message = "truststore_uri should be built as s3://<bucket_name>/truststore.pem when only bucket_name is set."
  }

  assert {
    condition     = aws_api_gateway_domain_name.this[0].mutual_tls_authentication[0].truststore_version == null
    error_message = "truststore_version should be null when not provided."
  }

  assert {
    condition     = output.truststore_uri == "s3://my-truststore-bucket/truststore.pem"
    error_message = "truststore_uri output should expose the resolved URI."
  }

  assert {
    condition     = output.truststore_version == null
    error_message = "truststore_version output should be null when not provided."
  }
}

run "mtls_builds_truststore_uri_from_bucket_name_and_custom_key" {
  command = plan

  variables {
    enable_mtls = true
    bucket_name = "my-truststore-bucket"
    mtls_config = {
      truststore_key     = "mtls/ca-bundle.pem"
      truststore_version = "3HL4kqtJlcpXroDTDmJ.rmSpXd3dIbrHY"
    }
  }

  assert {
    condition     = aws_api_gateway_domain_name.this[0].mutual_tls_authentication[0].truststore_uri == "s3://my-truststore-bucket/mtls/ca-bundle.pem"
    error_message = "truststore_uri should be built from bucket_name and mtls_config.truststore_key."
  }

  assert {
    condition     = aws_api_gateway_domain_name.this[0].mutual_tls_authentication[0].truststore_version == "3HL4kqtJlcpXroDTDmJ.rmSpXd3dIbrHY"
    error_message = "truststore_version should pass through to the domain name."
  }

  assert {
    condition     = output.truststore_uri == "s3://my-truststore-bucket/mtls/ca-bundle.pem"
    error_message = "truststore_uri output should expose the resolved URI."
  }

  assert {
    condition     = output.truststore_version == "3HL4kqtJlcpXroDTDmJ.rmSpXd3dIbrHY"
    error_message = "truststore_version output should expose the configured version."
  }
}

run "mtls_explicit_truststore_uri_without_bucket_name" {
  command = plan

  variables {
    enable_mtls = true
    mtls_config = {
      truststore_uri = "s3://legacy-bucket/legacy/truststore.pem"
    }
  }

  assert {
    condition     = aws_api_gateway_domain_name.this[0].mutual_tls_authentication[0].truststore_uri == "s3://legacy-bucket/legacy/truststore.pem"
    error_message = "An explicit truststore_uri must keep working on its own (backwards compatibility)."
  }

  assert {
    condition     = output.truststore_uri == "s3://legacy-bucket/legacy/truststore.pem"
    error_message = "truststore_uri output should expose the explicit URI."
  }
}

run "mtls_explicit_truststore_uri_wins_over_bucket_name" {
  command = plan

  variables {
    enable_mtls = true
    bucket_name = "my-truststore-bucket"
    mtls_config = {
      truststore_uri = "s3://legacy-bucket/legacy/truststore.pem"
      truststore_key = "ignored.pem"
    }
  }

  assert {
    condition     = aws_api_gateway_domain_name.this[0].mutual_tls_authentication[0].truststore_uri == "s3://legacy-bucket/legacy/truststore.pem"
    error_message = "An explicit truststore_uri must take precedence over bucket_name and truststore_key."
  }
}

run "mtls_requires_a_truststore_source" {
  command = plan

  variables {
    enable_mtls = true
  }

  expect_failures = [aws_api_gateway_domain_name.this]
}

run "mtls_requires_a_truststore_source_when_mtls_config_has_only_a_version" {
  command = plan

  variables {
    enable_mtls = true
    mtls_config = {
      truststore_version = "3HL4kqtJlcpXroDTDmJ.rmSpXd3dIbrHY"
    }
  }

  expect_failures = [aws_api_gateway_domain_name.this]
}

run "no_custom_domain_when_domain_name_is_null" {
  command = plan

  variables {
    domain_name     = null
    certificate_arn = null
    enable_mtls     = true
    bucket_name     = "my-truststore-bucket"
  }

  assert {
    condition     = length(aws_api_gateway_domain_name.this) == 0
    error_message = "No custom domain should be created when domain_name is null."
  }

  assert {
    condition     = length(aws_api_gateway_base_path_mapping.this) == 0
    error_message = "No base path mapping should be created when domain_name is null."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
