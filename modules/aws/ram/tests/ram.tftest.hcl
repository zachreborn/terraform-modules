mock_provider "aws" {
  mock_resource "aws_ram_resource_share" {
    defaults = {
      arn = "arn:aws:ram:us-east-1:123456789012:resource-share/0a1b2c3d-1234-5678-9abc-def012345678"
      id  = "0a1b2c3d-1234-5678-9abc-def012345678"
    }
  }

  mock_data "aws_organizations_organization" {
    defaults = {
      arn = "arn:aws:organizations::123456789012:organization/o-abcd1234"
      roots = [
        {
          id           = "r-abcd1234"
          arn          = "arn:aws:organizations::123456789012:root/o-abcd1234/r-abcd1234"
          name         = "Root"
          policy_types = []
        }
      ]
    }
  }
}

run "unknown_arn_fresh_deployment" {
  command = plan

  module {
    source = "./tests/fixtures/unknown_arns"
  }

  assert {
    condition     = keys(output.resource_association_ids) == ["transit"]
    error_message = "A new upstream resource with an apply-time ARN must plan an association under its known logical key."
  }
}

run "association_output_values" {
  command = apply

  variables {
    name = "output_wiring"
    resource_arns = {
      app_connectors = "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0123456789abcdef0"
      switches       = "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0fedcba9876543210"
    }
  }

  assert {
    condition = alltrue([
      for key, association in aws_ram_resource_association.this :
      output.resource_association_ids[key] == association.id && association.id != ""
    ])
    error_message = "Each output value must be the corresponding association's ID."
  }
}

run "valid_baseline_single_arn" {
  command = plan

  variables {
    name          = "transit_tgw"
    resource_arns = { transit = "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0" }
  }

  assert {
    condition     = output.arn == "arn:aws:ram:us-east-1:123456789012:resource-share/0a1b2c3d-1234-5678-9abc-def012345678"
    error_message = "The arn output must expose the resource share ARN."
  }

  assert {
    condition     = output.id == "0a1b2c3d-1234-5678-9abc-def012345678"
    error_message = "The id output must expose the resource share ID."
  }

  assert {
    condition     = length(aws_ram_resource_association.this) == 1
    error_message = "Exactly one resource association should be planned for a single-entry resource_arns map."
  }

  assert {
    condition     = length(output.resource_association_ids) == 1
    error_message = "resource_association_ids should contain exactly one entry for a single-entry resource_arns map."
  }

  assert {
    condition     = aws_ram_resource_association.this["transit"].resource_arn == var.resource_arns["transit"]
    error_message = "The transit association must receive the ARN value, not its logical key."
  }

  assert {
    condition     = aws_ram_resource_association.this["transit"].resource_share_arn == output.arn
    error_message = "The transit association must reference this resource share."
  }
}

run "multiple_arns_for_each_fan_out" {
  command = plan

  variables {
    name = "managed_prefix_lists"
    resource_arns = {
      app_connectors = "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0123456789abcdef0"
      switches       = "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0fedcba9876543210"
    }
  }

  assert {
    condition     = length(aws_ram_resource_association.this) == length(var.resource_arns)
    error_message = "The number of resource associations should match the number of supplied resource_arns."
  }

  assert {
    condition     = keys(output.resource_association_ids) == keys(var.resource_arns)
    error_message = "The association output keys must exactly match the supplied logical keys."
  }

  assert {
    condition     = alltrue([for k, v in aws_ram_resource_association.this : v.resource_arn == var.resource_arns[k]])
    error_message = "Each association's resource_arn must equal the value for its logical key."
  }
}

run "empty_map_for_each_zero_branch" {
  command = plan

  variables {
    name          = "empty_share"
    resource_arns = {}
  }

  assert {
    condition     = length(aws_ram_resource_association.this) == 0
    error_message = "No resource associations should be planned when resource_arns is empty."
  }

  assert {
    condition     = length(output.resource_association_ids) == 0
    error_message = "resource_association_ids should be empty when resource_arns is empty."
  }

  assert {
    condition     = output.arn != null
    error_message = "The resource share itself should still plan successfully with an empty resource_arns map."
  }
}

run "principal_fallback_branch_unset" {
  command = plan

  variables {
    name          = "transit_tgw"
    resource_arns = { transit = "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0" }
    principal     = null
  }

  assert {
    condition     = aws_ram_principal_association.this.principal == "arn:aws:organizations::123456789012:organization/o-abcd1234"
    error_message = "The principal association should fall back to the mocked organization arn when var.principal is unset."
  }
}

run "principal_explicit_branch_set" {
  command = plan

  variables {
    name          = "transit_tgw"
    resource_arns = { transit = "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0" }
    principal     = "arn:aws:organizations::123456789012:ou/o-abcd1234/ou-abcd-11111111"
  }

  assert {
    condition     = aws_ram_principal_association.this.principal == "arn:aws:organizations::123456789012:ou/o-abcd1234/ou-abcd-11111111"
    error_message = "The principal association should use the explicitly supplied principal when var.principal is set."
  }
}
