mock_provider "aws" {
  mock_resource "aws_dx_connection" {
    defaults = {
      id                     = "dxcon-mock1234"
      arn                    = "arn:aws:directconnect:us-east-1:123456789012:dxcon/dxcon-mock1234"
      aws_device             = "EqDC2-1abc2def"
      has_logical_redundancy = "yes"
      jumbo_frame_capable    = true
      macsec_capable         = false
      owner_account_id       = "123456789012"
      partner_name           = "Example Partner"
      port_encryption_status = "Encryption Down"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name      = "example-connection"
    bandwidth = "1Gbps"
    location  = "EqDC2"
  }

  assert {
    condition     = aws_dx_connection.this.encryption_mode == "no_encrypt"
    error_message = "encryption_mode should default to no_encrypt."
  }

  assert {
    condition     = aws_dx_connection.this.request_macsec == false
    error_message = "request_macsec should default to false."
  }

  # region is Optional and Computed on aws_dx_connection (AWS provider v6's per-resource
  # Region override feature), so the mock provider generates fake data for it when unset --
  # there is no meaningful "defaults to null" case to assert via mocks. The override case in
  # the "overrides_are_honored" run below is sufficient to prove the module wires var.region
  # through.

  assert {
    condition     = aws_dx_connection.this.tags["Name"] == "example-connection"
    error_message = "A Name tag should default to var.name."
  }

  assert {
    condition     = output.arn == "arn:aws:directconnect:us-east-1:123456789012:dxcon/dxcon-mock1234"
    error_message = "arn output should expose the mocked connection ARN."
  }

  assert {
    condition     = output.id == "dxcon-mock1234"
    error_message = "id output should expose the mocked connection id."
  }

  assert {
    condition     = output.has_logical_redundancy == "yes"
    error_message = "has_logical_redundancy output should expose the mocked value."
  }

  assert {
    condition     = output.macsec_capable == false
    error_message = "macsec_capable output should expose the mocked value."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    name            = "example-connection"
    bandwidth       = "10Gbps"
    location        = "EqDA2"
    encryption_mode = "must_encrypt"
    provider_name   = "Example Provider"
    region          = "us-west-2"
    request_macsec  = true
    tags = {
      team = "networking"
    }
  }

  assert {
    condition     = aws_dx_connection.this.encryption_mode == "must_encrypt"
    error_message = "encryption_mode override should be honored."
  }

  assert {
    condition     = aws_dx_connection.this.provider_name == "Example Provider"
    error_message = "provider_name override should be honored."
  }

  assert {
    condition     = aws_dx_connection.this.region == "us-west-2"
    error_message = "region override should be passed through to aws_dx_connection.this."
  }

  assert {
    condition     = aws_dx_connection.this.request_macsec == true
    error_message = "request_macsec override should be honored."
  }

  assert {
    condition     = aws_dx_connection.this.tags["team"] == "networking"
    error_message = "Caller-provided tags should be merged in."
  }

  assert {
    condition     = aws_dx_connection.this.tags["Name"] == "example-connection"
    error_message = "Name tag should still be present alongside merged tags."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
