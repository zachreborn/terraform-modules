# Native OpenTofu tests for the directconnect/connection module. All cases run fully
# offline via `mock_provider`/`mock_resource` -- no real credentials or backend required:
#   tofu init -backend=false && tofu test
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full
# requirement, and modules/aws/organizations/account/tests/ for a worked example.

mock_provider "aws" {
  mock_resource "aws_dx_connection" {
    defaults = {
      id                     = "dxcon-fguhmqlc"
      arn                    = "arn:aws:directconnect:us-east-1:123456789012:dxcon/dxcon-fguhmqlc"
      aws_device             = "EqDC2-1a2b3c4d5e6f"
      has_logical_redundancy = "unknown"
      jumbo_frame_capable    = true
      macsec_capable         = false
      owner_account_id       = "123456789012"
      partner_name           = ""
      port_encryption_status = "Unknown"
      vlan_id                = 100
      tags_all               = {}
    }
  }
}

# Valid baseline: a dedicated connection with only the required arguments must plan.
run "plan_succeeds_with_required_variables" {
  command = plan

  variables {
    connection_name = "my-dx-connection"
    location        = "EqDC2"
    bandwidth       = "10Gbps"
  }

  assert {
    condition     = aws_dx_connection.this.name == "my-dx-connection"
    error_message = "The connection name should match the connection_name variable."
  }

  assert {
    condition     = aws_dx_connection.this.request_macsec == false
    error_message = "request_macsec should default to false."
  }
}

# MACsec + encryption_mode: a dedicated connection requesting MACsec with an explicit
# encryption_mode must plan successfully.
run "plan_succeeds_with_macsec_and_encryption_mode" {
  command = plan

  variables {
    connection_name = "my-dx-connection"
    location        = "EqDC2"
    bandwidth       = "10Gbps"
    request_macsec  = true
    encryption_mode = "should_encrypt"
    provider_name   = "Example Partner"
  }

  assert {
    condition     = aws_dx_connection.this.request_macsec == true
    error_message = "request_macsec should be true when explicitly requested."
  }

  assert {
    condition     = aws_dx_connection.this.encryption_mode == "should_encrypt"
    error_message = "encryption_mode should be forwarded to the resource."
  }

  assert {
    condition     = aws_dx_connection.this.provider_name == "Example Partner"
    error_message = "provider_name should be forwarded to the resource."
  }
}

# Validation failure: encryption_mode must be one of the documented enum values.
run "rejects_invalid_encryption_mode" {
  command = plan

  variables {
    connection_name = "my-dx-connection"
    location        = "EqDC2"
    bandwidth       = "10Gbps"
    encryption_mode = "always_encrypt"
  }

  expect_failures = [var.encryption_mode]
}

# Output assertions against the mocked resource values.
run "outputs_are_populated" {
  command = apply

  variables {
    connection_name = "my-dx-connection"
    location        = "EqDC2"
    bandwidth       = "10Gbps"
  }

  assert {
    condition     = output.id == "dxcon-fguhmqlc"
    error_message = "The id output should match the mocked connection ID."
  }

  assert {
    condition     = output.arn != null
    error_message = "The arn output should be non-null."
  }

  assert {
    condition     = output.owner_account_id == "123456789012"
    error_message = "The owner_account_id output should match the mocked value."
  }

  assert {
    condition     = output.vlan_id == 100
    error_message = "The vlan_id output should match the mocked value."
  }
}

# Do NOT weaken these assertions to force a pass. A failing test is a signal that
# something is wrong in main.tf/variables.tf/outputs.tf -- fix the root cause there.
