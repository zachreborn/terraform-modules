mock_provider "aws" {
  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn         = "arn:aws:iam::123456789012:instance-profile/mock-profile"
      id          = "mock-profile"
      unique_id   = "AIPAMOCKUNIQUEID12345"
      create_date = "2026-01-01T00:00:00Z"
      tags_all = {
        Name      = "example-profile"
        terraform = "true"
        Team      = "platform"
      }
    }
  }
}

run "caller_name_tag_overrides_merged_name" {
  command = plan

  variables {
    tags = { Name = "caller-selected-name" }
  }

  assert {
    condition     = aws_iam_instance_profile.this.tags == tomap({ Name = "caller-selected-name" })
    error_message = "Caller tags must override the merged Name without restoring default tags."
  }
}

run "empty_tags_replace_defaults_with_prefix" {
  command = plan

  variables {
    name        = null
    name_prefix = "example-"
    tags        = {}
  }

  assert {
    condition     = length(aws_iam_instance_profile.this.tags) == 0
    error_message = "An explicitly empty tag map and a prefix must produce no configured tags."
  }
}

variables {
  name = "example-profile"
  role = "example-role"
}

run "plan_succeeds_with_valid_baseline" {
  command = plan

  assert {
    condition     = aws_iam_instance_profile.this.name == "example-profile"
    error_message = "The configured name must reach the instance profile."
  }

  assert {
    # name_prefix is Optional+Computed: the mock fills it even when omitted.
    # Check the actual configuration expression, not the computed planned value.
    condition = var.name_prefix == null && can(regex(
      "name_prefix\\s*=\\s*var\\.name_prefix != null \\? var\\.name_prefix : null",
      file("${path.module}/main.tf")
    ))
    error_message = "The name branch must configure name_prefix as null, leaving it to the provider."
  }

  assert {
    condition     = aws_iam_instance_profile.this.path == "/"
    error_message = "The default path must be /."
  }

  assert {
    condition     = aws_iam_instance_profile.this.role == "example-role"
    error_message = "The role name must reach the instance profile unchanged."
  }
}

run "profile_is_the_only_resource_type_planned" {
  command = plan

  assert {
    condition     = aws_iam_instance_profile.this.name == "example-profile"
    error_message = "The single instance profile must plan successfully."
  }

  # A mock_provider also auto-mocks unspecified types. Pin the complete resource
  # inventory in every module .tf file instead of treating mock_resource as an allowlist.
  assert {
    condition = flatten([
      for source in sort(tolist(fileset(path.module, "*.tf"))) :
      regexall("(?m)^\\s*resource\\s+\"([^\"]+)\"\\s+\"([^\"]+)\"\\s*\\{", file("${path.module}/${source}"))
    ]) == ["aws_iam_instance_profile", "this"]
    error_message = "The module must declare exactly one resource: aws_iam_instance_profile.this."
  }

  assert {
    condition = alltrue([
      for source in fileset(path.module, "*.tf") :
      length(regexall("(?m)^\\s*(module|data)\\s+\"", file("${path.module}/${source}"))) == 0
    ])
    error_message = "The profile module must not introduce child modules or role lookups."
  }
}

run "outputs_expose_profile_attributes" {
  command = plan

  assert {
    condition     = output.arn == "arn:aws:iam::123456789012:instance-profile/mock-profile"
    error_message = "arn must expose the resource's ARN."
  }

  assert {
    condition     = output.id == "mock-profile"
    error_message = "id must expose the resource's ID."
  }

  assert {
    condition     = output.unique_id == "AIPAMOCKUNIQUEID12345"
    error_message = "unique_id must expose the AWS-assigned unique ID."
  }

  assert {
    condition     = output.create_date == "2026-01-01T00:00:00Z"
    error_message = "create_date must expose the resource's creation timestamp."
  }

  assert {
    condition     = output.name == "example-profile"
    error_message = "name must expose the configured profile name."
  }

  assert {
    condition     = output.path == "/"
    error_message = "path must expose the applied default path."
  }

  assert {
    condition     = output.role == "example-role"
    error_message = "role must expose the attached role name."
  }

  # tags_all is computed by the provider, unlike the configured tags map.
  assert {
    condition = output.tags_all == tomap({
      Name      = "example-profile"
      terraform = "true"
      Team      = "platform"
    })
    error_message = "tags_all must expose all resource tags, including inherited provider tags."
  }
}

run "arn_output_matches_instance_profile_arn_shape" {
  command = plan

  assert {
    condition     = can(regex("^arn:aws[a-z-]*:iam::[0-9]{12}:instance-profile/", output.arn))
    error_message = "arn must have an IAM instance-profile ARN shape."
  }
}

run "role_binding_matches_role_input" {
  command = plan

  variables {
    role = "custom-role-name"
  }

  assert {
    condition     = aws_iam_instance_profile.this.role == "custom-role-name"
    error_message = "The resource must bind the supplied role name."
  }

  assert {
    condition     = output.role == "custom-role-name"
    error_message = "The role output must reflect the resource's attached role."
  }
}

run "custom_path_and_tags_are_applied" {
  command = plan

  variables {
    path = "/service-role/"
    tags = { Environment = "sandbox" }
  }

  assert {
    condition     = aws_iam_instance_profile.this.path == "/service-role/" && output.path == "/service-role/"
    error_message = "The custom path must reach the resource and output."
  }

  assert {
    condition     = aws_iam_instance_profile.this.tags["Environment"] == "sandbox"
    error_message = "Caller tags must reach the profile."
  }

  assert {
    condition     = aws_iam_instance_profile.this.tags["Name"] == "example-profile"
    error_message = "The configured name must be merged into tags."
  }

  assert {
    condition     = !contains(keys(aws_iam_instance_profile.this.tags), "terraform")
    error_message = "Caller tags must replace, not merge with, the default map."
  }
}

run "default_tags_are_applied_when_tags_are_omitted" {
  command = plan

  assert {
    condition     = aws_iam_instance_profile.this.tags == tomap({ terraform = "true", Name = "example-profile" })
    error_message = "Omitted tags must retain the terraform default and merged Name."
  }
}

run "name_prefix_branch_sets_prefix_and_omits_name" {
  command = plan

  variables {
    name        = null
    name_prefix = "example-"
  }

  assert {
    condition     = aws_iam_instance_profile.this.name_prefix == "example-"
    error_message = "The prefix branch must pass the supplied prefix to the resource."
  }

  assert {
    # name is Optional+Computed too. Prove the configured name is null while
    # leaving the generated resource name unmocked.
    condition = var.name == null && can(regex(
      "name\\s*=\\s*var\\.name_prefix == null \\? var\\.name : null",
      file("${path.module}/main.tf")
    ))
    error_message = "The prefix branch must configure name as null, leaving generation to the provider."
  }

  assert {
    condition     = output.name == aws_iam_instance_profile.this.name
    error_message = "The name output must expose the provider-generated resource name."
  }

  assert {
    condition     = !contains(keys(aws_iam_instance_profile.this.tags), "Name")
    error_message = "The prefix branch must omit the Name tag, not set it to null."
  }
}

run "name_branch_omits_name_prefix" {
  command = plan

  assert {
    condition = var.name_prefix == null && can(regex(
      "name_prefix\\s*=\\s*var\\.name_prefix != null \\? var\\.name_prefix : null",
      file("${path.module}/main.tf")
    ))
    error_message = "The explicit-name branch must configure name_prefix as null."
  }
}
