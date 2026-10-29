mock_provider "aws" {
  mock_resource "aws_ram_resource_share" {
    defaults = {
      arn = "arn:aws:ram:us-east-1:123456789012:resource-share/0a1b2c3d-1234-5678-9abc-def012345678"
    }
  }

  mock_resource "aws_vpc_ipam_pool" {
    defaults = {
      arn = "arn:aws:ec2:us-east-1:123456789012:ipam-pool/ipam-pool-0123456789abcdef0"
    }
  }

  mock_data "aws_organizations_organization" {
    defaults = {
      arn = "arn:aws:organizations::123456789012:organization/o-abcd1234"
    }
  }
}

variables {
  name              = "ram_wiring"
  operating_regions = ["us-east-1"]
  pools = {
    primary = {
      address_family = "ipv4"
      locale         = "us-east-1"
    }
  }
}

run "sharing_disabled" {
  command = plan

  assert {
    condition     = length(module.ram) == 0 && length(output.ram_share_arns) == 0
    error_message = "No shares should be created unless pool sharing is requested."
  }
}

run "organization_sharing" {
  command = plan

  variables {
    share_with_organization = true
    ram_share_pool_keys     = ["primary"]
  }

  assert {
    condition     = keys(module.ram["primary-org"].resource_association_ids) == ["primary"]
    error_message = "The pool's logical key must be passed to the RAM child module."
  }

  assert {
    condition     = output.ram_share_arns["primary-org"] == "arn:aws:ram:us-east-1:123456789012:resource-share/0a1b2c3d-1234-5678-9abc-def012345678"
    error_message = "The organization share output must expose the child module's share ARN."
  }
}

run "principal_sharing" {
  command = plan

  variables {
    ram_share_pool_keys = ["primary"]
    ram_principals      = ["123456789012", "234567890123"]
  }

  assert {
    condition     = keys(output.ram_share_arns) == ["primary-0", "primary-1"]
    error_message = "One resource share must be created per pool and principal pair."
  }

  assert {
    condition = alltrue([
      for share in module.ram : keys(share.resource_association_ids) == ["primary"]
    ])
    error_message = "Every principal's share must use the stable pool key for its association."
  }
}
