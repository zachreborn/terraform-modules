mock_provider "aws" {
  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mock-flow-logs-role"
    }
  }
  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mock-flow-logs-policy"
    }
  }
  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:mock-flow-logs-group"
    }
  }
}

# CloudWatch Logs encryption only supports symmetric KMS keys, so an
# asymmetric key spec must be rejected by the module's own validation
# instead of failing later at apply against AWS.
run "rejects_asymmetric_key_customer_master_key_spec" {
  command = plan

  variables {
    flow_vpc_ids                 = ["vpc-0123456789abcdef0"]
    key_customer_master_key_spec = "RSA_2048"
  }

  expect_failures = [
    var.key_customer_master_key_spec,
  ]
}

# The KMS key encrypts a CloudWatch Logs log group, which requires an
# encrypt/decrypt-capable key -- a SIGN_VERIFY key is valid in general but
# unusable here, so it must be rejected at validation time.
run "rejects_sign_verify_key_usage" {
  command = plan

  variables {
    flow_vpc_ids = ["vpc-0123456789abcdef0"]
    key_usage    = "SIGN_VERIFY"
  }

  expect_failures = [
    var.key_usage,
  ]
}
