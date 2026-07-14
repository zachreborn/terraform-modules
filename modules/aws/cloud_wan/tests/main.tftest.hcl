mock_provider "aws" {
  mock_resource "aws_networkmanager_global_network" {
    defaults = {
      id  = "gn-01234567890abcdef"
      arn = "arn:aws:networkmanager::123456789012:global-network/gn-01234567890abcdef"
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    name                 = "example-global-network"
    transit_gateway_arns = ["arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"]
  }

  assert {
    condition     = aws_networkmanager_global_network.this.description == null
    error_message = "description should default to null when unset."
  }

  assert {
    condition     = aws_networkmanager_global_network.this.tags["Name"] == "example-global-network"
    error_message = "tags should be merged with a Name key set to var.name."
  }

  assert {
    condition     = length(aws_networkmanager_transit_gateway_registration.this) == 1
    error_message = "Expected exactly one transit gateway registration for a single ARN."
  }

  assert {
    condition     = output.global_network_arn == "arn:aws:networkmanager::123456789012:global-network/gn-01234567890abcdef"
    error_message = "global_network_arn output should expose the global network's arn."
  }
}

run "no_transit_gateway_arns_creates_no_registrations" {
  command = plan

  variables {
    name                 = "example-global-network"
    transit_gateway_arns = []
  }

  assert {
    condition     = length(aws_networkmanager_transit_gateway_registration.this) == 0
    error_message = "Expected no transit gateway registrations when transit_gateway_arns is empty."
  }
}

run "duplicate_transit_gateway_arns_are_deduplicated_by_toset" {
  command = plan

  variables {
    name = "example-global-network"
    transit_gateway_arns = [
      "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0",
      "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0",
    ]
  }

  assert {
    condition     = length(aws_networkmanager_transit_gateway_registration.this) == 1
    error_message = "toset() should deduplicate identical transit gateway ARNs into a single registration."
  }
}

run "description_override_is_honored" {
  command = plan

  variables {
    name                 = "example-global-network"
    description          = "custom description"
    transit_gateway_arns = []
  }

  assert {
    condition     = aws_networkmanager_global_network.this.description == "custom description"
    error_message = "description override should be honored."
  }
}

run "custom_tags_merge_with_computed_name_tag" {
  command = plan

  variables {
    name                 = "example-global-network"
    transit_gateway_arns = []
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_networkmanager_global_network.this.tags["team"] == "platform"
    error_message = "Custom tags should be present alongside the Name tag."
  }

  assert {
    condition     = aws_networkmanager_global_network.this.tags["Name"] == "example-global-network"
    error_message = "Name tag should still be merged in even when custom tags are supplied."
  }
}

# Do NOT weaken these assertions to force a pass. If a run block fails, treat it as a
# signal that the module code has a bug and fix the root cause in main.tf / variables.tf /
# outputs.tf, then re-run `tofu test` until it passes for the right reason.
