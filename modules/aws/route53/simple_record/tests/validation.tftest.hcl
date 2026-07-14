mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "TXT"
    records = ["sample-txt-value"]
  }

  assert {
    condition     = aws_route53_record.this.type == "TXT"
    error_message = "Expected a plan with a valid record type."
  }
}

run "rejects_invalid_type" {
  command = plan

  variables {
    zone_id = "Z1234567890EXAMPLE"
    name    = "www.example.com"
    type    = "BOGUS"
    records = ["sample-txt-value"]
  }

  expect_failures = [var.type]
}
