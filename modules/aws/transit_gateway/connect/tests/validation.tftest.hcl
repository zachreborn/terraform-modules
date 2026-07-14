mock_provider "aws" {}

run "valid_baseline_does_not_fail" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    peers                   = {}
  }

  assert {
    condition     = aws_ec2_transit_gateway_connect.connect_attachment.protocol == "gre"
    error_message = "Default protocol value should satisfy validation and plan successfully."
  }
}

run "rejects_unsupported_protocol" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    protocol                = "gretap"
    peers                   = {}
  }

  expect_failures = [var.protocol]
}

run "rejects_empty_protocol" {
  command = plan

  variables {
    name                    = "sdwan-connect"
    transport_attachment_id = "tgw-attach-0123456789abcdef0"
    transit_gateway_id      = "tgw-0123456789abcdef0"
    protocol                = ""
    peers                   = {}
  }

  expect_failures = [var.protocol]
}
