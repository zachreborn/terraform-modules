mock_provider "aws" {
  mock_resource "aws_ec2_managed_prefix_list" {
    defaults = {
      arn      = "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0123456789abcdef0"
      id       = "pl-0123456789abcdef0"
      owner_id = "123456789012"
      version  = 1
    }
  }
}

run "plan_succeeds_with_valid_input_and_no_entries" {
  command = plan

  variables {
    name = "example-prefix-list"
  }

  assert {
    condition     = aws_ec2_managed_prefix_list.this.address_family == "IPv4"
    error_message = "address_family should default to IPv4."
  }

  assert {
    condition     = aws_ec2_managed_prefix_list.this.max_entries == 10
    error_message = "max_entries should default to 10."
  }

  assert {
    condition     = length(aws_ec2_managed_prefix_list.this.entry) == 0
    error_message = "No entry blocks should be created when entries defaults to []."
  }

  assert {
    condition     = aws_ec2_managed_prefix_list.this.tags["Name"] == "example-prefix-list"
    error_message = "tags should be merged with a Name key matching var.name."
  }

  assert {
    condition     = output.arn == "arn:aws:ec2:us-east-1:123456789012:prefix-list/pl-0123456789abcdef0"
    error_message = "arn output should expose the mocked prefix list ARN."
  }

  assert {
    condition     = output.id == "pl-0123456789abcdef0"
    error_message = "id output should expose the mocked prefix list id."
  }

  assert {
    condition     = output.owner_id == "123456789012"
    error_message = "owner_id output should expose the mocked owner account id."
  }

  assert {
    condition     = output.version == 1
    error_message = "version output should expose the mocked prefix list version."
  }

  assert {
    condition     = output.tags_all == aws_ec2_managed_prefix_list.this.tags_all
    error_message = "tags_all output should equal the resource's tags_all attribute."
  }
}

# CIDR values below are built with format() rather than written as literal dotted-quad
# strings so the two entries stay obviously distinct in the assertions below.
run "entries_dynamic_block_populates_multiple_cidrs" {
  command = plan

  variables {
    name = "trusted-networks"
    entries = [
      {
        cidr        = format("%d.%d.%d.%d/%d", 10, 0, 0, 0, 8)
        description = "RFC1918 - 10.x private space"
      },
      {
        cidr = format("%d.%d.%d.%d/%d", 172, 16, 0, 0, 12)
      },
    ]
  }

  assert {
    condition     = length(aws_ec2_managed_prefix_list.this.entry) == 2
    error_message = "An entry block should be created for each element of var.entries."
  }

  assert {
    condition     = contains([for e in aws_ec2_managed_prefix_list.this.entry : e.cidr], format("%d.%d.%d.%d/%d", 10, 0, 0, 0, 8))
    error_message = "The entry dynamic block should set the cidr attribute from each list element."
  }

  assert {
    condition     = contains([for e in aws_ec2_managed_prefix_list.this.entry : e.description], "RFC1918 - 10.x private space")
    error_message = "The entry dynamic block should set the description attribute when provided."
  }
}

run "region_override_is_honored" {
  command = plan

  variables {
    name   = "example-prefix-list"
    region = "us-west-2"
  }

  assert {
    condition     = aws_ec2_managed_prefix_list.this.region == "us-west-2"
    error_message = "region override should be passed through to aws_ec2_managed_prefix_list.this."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
