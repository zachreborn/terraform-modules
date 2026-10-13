mock_provider "aws" {
  mock_resource "aws_ram_resource_share" {
    defaults = {
      arn = "arn:aws:ram:us-east-1:123456789012:resource-share/0a1b2c3d-1234-5678-9abc-def012345678"
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

run "valid_baseline_single_arn" {
  command = plan

  variables {
    name          = "transit_tgw"
    resource_arns = ["arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"]
  }

  assert {
    condition     = output.arn != null
    error_message = "The resource share arn output should be non-null."
  }

  assert {
    condition     = output.id != null
    error_message = "The resource share id output should be non-null."
  }

  assert {
    condition     = length(aws_ram_resource_association.this) == 1
    error_message = "Exactly one resource association should be planned for a single-element resource_arns list."
  }

  assert {
    condition     = length(output.resource_association_ids) == 1
    error_message = "resource_association_ids should contain exactly one entry for a single-element resource_arns list."
  }
}

run "multiple_arns_for_each_fan_out" {
  command = plan

  variables {
    name = "managed_prefix_lists"
    resource_arns = [
      "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0123456789abcdef0",
      "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0fedcba9876543210",
    ]
  }

  assert {
    condition     = length(aws_ram_resource_association.this) == length(var.resource_arns)
    error_message = "The number of resource associations should match the number of supplied resource_arns."
  }

  assert {
    condition     = alltrue([for arn in var.resource_arns : contains(keys(output.resource_association_ids), arn)])
    error_message = "Every supplied ARN should be a key in resource_association_ids."
  }

  assert {
    condition     = alltrue([for k, v in aws_ram_resource_association.this : v.resource_arn == k])
    error_message = "Each association's resource_arn should equal its for_each map key."
  }
}

run "empty_list_for_each_zero_branch" {
  command = plan

  variables {
    name          = "empty_share"
    resource_arns = []
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
    error_message = "The resource share itself should still plan successfully with an empty resource_arns list."
  }
}

run "principal_fallback_branch_unset" {
  command = plan

  variables {
    name          = "transit_tgw"
    resource_arns = ["arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"]
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
    resource_arns = ["arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"]
    principal     = "arn:aws:organizations::123456789012:ou/o-abcd1234/ou-abcd-11111111"
  }

  assert {
    condition     = aws_ram_principal_association.this.principal == "arn:aws:organizations::123456789012:ou/o-abcd1234/ou-abcd-11111111"
    error_message = "The principal association should use the explicitly supplied principal when var.principal is set."
  }
}
