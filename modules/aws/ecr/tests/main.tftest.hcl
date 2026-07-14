mock_provider "aws" {
  mock_resource "aws_ecr_repository" {
    defaults = {
      arn            = "arn:aws:ecr:us-east-1:123456789012:repository/mock-repo"
      id             = "123456789012"
      registry_id    = "123456789012"
      repository_url = "123456789012.dkr.ecr.us-east-1.amazonaws.com/mock-repo"
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name = "example-repo"
  }

  assert {
    condition     = aws_ecr_repository.this.name == "example-repo"
    error_message = "name should pass through unchanged."
  }

  assert {
    condition     = aws_ecr_repository.this.force_delete == false
    error_message = "force_delete should default to false."
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "IMMUTABLE"
    error_message = "image_tag_mutability should default to IMMUTABLE."
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == true
    error_message = "scan_on_push should default to true."
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "KMS"
    error_message = "encryption_type should default to KMS."
  }

  assert {
    condition     = aws_ecr_repository.this.tags["Name"] == "example-repo"
    error_message = "Name tag should default to the repository name."
  }

  assert {
    condition     = aws_ecr_repository.this.tags["terraform"] == "true"
    error_message = "tags should default to include terraform = true."
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 0
    error_message = "No lifecycle policy resource should be created when lifecycle_policy is null."
  }

  assert {
    condition     = length(aws_ecr_repository_policy.this) == 0
    error_message = "No repository policy resource should be created when repository_policy is null."
  }

  assert {
    condition     = output.arn == "arn:aws:ecr:us-east-1:123456789012:repository/mock-repo"
    error_message = "arn output should expose the mocked repository ARN."
  }

  assert {
    condition     = output.id == "123456789012"
    error_message = "id output should expose the mocked repository id."
  }

  assert {
    condition     = output.registry_id == "123456789012"
    error_message = "registry_id output should expose the mocked registry id."
  }

  assert {
    condition     = output.repository_url == "123456789012.dkr.ecr.us-east-1.amazonaws.com/mock-repo"
    error_message = "repository_url output should expose the mocked repository url."
  }

  assert {
    condition     = output.tags_all == aws_ecr_repository.this.tags_all
    error_message = "tags_all output should expose the repository's tags_all attribute."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    name                 = "custom-repo"
    force_delete         = true
    image_tag_mutability = "MUTABLE"
    scan_on_push         = false
    encryption_type      = "KMS"
    kms_key              = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    tags = {
      Name = "custom-name-tag"
      team = "platform"
    }
  }

  assert {
    condition     = aws_ecr_repository.this.force_delete == true
    error_message = "force_delete override should be honored."
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability == "MUTABLE"
    error_message = "image_tag_mutability override should be honored."
  }

  assert {
    condition     = aws_ecr_repository.this.image_scanning_configuration[0].scan_on_push == false
    error_message = "scan_on_push override should be honored."
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].kms_key == "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    error_message = "kms_key override should be honored when encryption_type is KMS."
  }

  assert {
    condition     = aws_ecr_repository.this.tags["Name"] == "custom-name-tag"
    error_message = "An explicit Name tag in var.tags should override the module's default Name tag."
  }

  assert {
    condition     = aws_ecr_repository.this.tags["team"] == "platform"
    error_message = "Additional custom tags should be honored."
  }
}

run "kms_key_is_ignored_when_encryption_type_is_aes256" {
  command = plan

  variables {
    name            = "example-repo"
    encryption_type = "AES256"
    kms_key         = "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
  }

  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].encryption_type == "AES256"
    error_message = "encryption_type override should be honored."
  }

  # kms_key is Optional+Computed in the aws_ecr_repository schema, so a `null` config value
  # is planned as unknown (and OpenTofu's mock provider fills unknowns with a generated
  # placeholder) rather than staying null -- asserting `== null` here would fail even though
  # the module is behaving correctly. Instead we assert that var.kms_key was NOT forwarded,
  # which is what the encryption_type == "KMS" ? var.kms_key : null ternary guarantees.
  assert {
    condition     = aws_ecr_repository.this.encryption_configuration[0].kms_key != "arn:aws:kms:us-east-1:123456789012:key/1234abcd-12ab-34cd-56ef-1234567890ab"
    error_message = "var.kms_key should not be forwarded to the encryption_configuration when encryption_type is not KMS."
  }
}

run "lifecycle_policy_creates_resource_when_set" {
  command = plan

  variables {
    name             = "example-repo"
    lifecycle_policy = "{\"rules\":[]}"
  }

  assert {
    condition     = length(aws_ecr_lifecycle_policy.this) == 1
    error_message = "Setting lifecycle_policy should create exactly one aws_ecr_lifecycle_policy resource."
  }

  assert {
    condition     = aws_ecr_lifecycle_policy.this[0].policy == "{\"rules\":[]}"
    error_message = "lifecycle_policy value should be passed through to the resource."
  }
}

run "repository_policy_creates_resource_when_set" {
  command = plan

  variables {
    name              = "example-repo"
    repository_policy = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }

  assert {
    condition     = length(aws_ecr_repository_policy.this) == 1
    error_message = "Setting repository_policy should create exactly one aws_ecr_repository_policy resource."
  }

  assert {
    condition     = aws_ecr_repository_policy.this[0].policy == "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    error_message = "repository_policy value should be passed through to the resource."
  }
}

run "image_tag_mutability_exclusion_filter_defaults_to_no_filters" {
  command = plan

  variables {
    name = "example-repo"
  }

  assert {
    condition     = length(aws_ecr_repository.this.image_tag_mutability_exclusion_filter) == 0
    error_message = "image_tag_mutability_exclusion_filter should produce no nested blocks when unset."
  }
}

run "image_tag_mutability_exclusion_filter_creates_entries_when_set" {
  command = plan

  variables {
    name                                  = "example-repo"
    image_tag_mutability                  = "IMMUTABLE_WITH_EXCLUSION"
    image_tag_mutability_exclusion_filter = ["latest*", "release-*"]
  }

  assert {
    condition     = length(aws_ecr_repository.this.image_tag_mutability_exclusion_filter) == 2
    error_message = "Setting image_tag_mutability_exclusion_filter should produce one nested block per entry."
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability_exclusion_filter[0].filter == "latest*"
    error_message = "The first exclusion filter's filter value should match the first list entry."
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability_exclusion_filter[0].filter_type == "WILDCARD"
    error_message = "filter_type should always be WILDCARD."
  }

  assert {
    condition     = aws_ecr_repository.this.image_tag_mutability_exclusion_filter[1].filter == "release-*"
    error_message = "The second exclusion filter's filter value should match the second list entry."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
