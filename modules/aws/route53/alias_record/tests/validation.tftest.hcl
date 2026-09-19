mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    zone_id                      = "Z1234567890EXAMPLE"
    name                         = "www.example.com"
    type                         = "A"
    alias_name                   = "d123456abcdef8.cloudfront.net"
    alias_zone_id                = "Z2FDTNDATAQYW2"
    alias_evaluate_target_health = false
  }

  assert {
    condition     = aws_route53_record.this.type == "A"
    error_message = "Expected a plan with a valid record type."
  }
}

run "rejects_invalid_type" {
  command = plan

  variables {
    zone_id                      = "Z1234567890EXAMPLE"
    name                         = "www.example.com"
    type                         = "BOGUS"
    alias_name                   = "d123456abcdef8.cloudfront.net"
    alias_zone_id                = "Z2FDTNDATAQYW2"
    alias_evaluate_target_health = false
  }

  expect_failures = [var.type]
}
