mock_provider "aws" {}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    name = "test-log-group"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.name == "test-log-group"
    error_message = "name should pass through unchanged."
  }
}

run "field_defaults_are_applied" {
  command = plan

  variables {
    name = "test-log-group"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.kms_key_id == null
    error_message = "kms_key_id has no module-level default -- it must stay null when unset."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.log_group_class == "STANDARD"
    error_message = "log_group_class should default to STANDARD."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 90
    error_message = "retention_in_days should default to 90."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.skip_destroy == false
    error_message = "skip_destroy should default to false."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.tags["terraform"] == "true"
    error_message = "Default tags should include terraform = true."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.tags["Name"] == "test-log-group"
    error_message = "Name tag should default to coalesce(var.name, var.name_prefix)."
  }
}

run "field_overrides_are_honored" {
  command = plan

  variables {
    name              = "test-log-group"
    kms_key_id        = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
    log_group_class   = "INFREQUENT_ACCESS"
    retention_in_days = 14
    skip_destroy      = true
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.kms_key_id == "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
    error_message = "kms_key_id override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.log_group_class == "INFREQUENT_ACCESS"
    error_message = "log_group_class override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.retention_in_days == 14
    error_message = "retention_in_days override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.skip_destroy == true
    error_message = "skip_destroy override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.tags["team"] == "platform"
    error_message = "Explicit tags should be honored."
  }

  assert {
    condition     = !contains(keys(aws_cloudwatch_log_group.this.tags), "terraform")
    error_message = "An explicit tags override should fully replace the default tags map (no merge with the terraform=true default)."
  }
}

run "name_prefix_branch_is_used_instead_of_name" {
  command = plan

  variables {
    name_prefix = "test-log-group-"
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.name_prefix == "test-log-group-"
    error_message = "name_prefix should pass through unchanged when used instead of name."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.tags["Name"] == "test-log-group-"
    error_message = "Name tag should coalesce to name_prefix when name is unset."
  }
}

run "outputs_expose_resource_attributes" {
  command = plan

  variables {
    name = "test-log-group"
  }

  assert {
    condition     = output.arn == aws_cloudwatch_log_group.this.arn
    error_message = "arn output should be wired to the log group's arn."
  }

  assert {
    condition     = output.id == aws_cloudwatch_log_group.this.id
    error_message = "id output should be wired to the log group's id."
  }

  assert {
    condition     = output.name == "test-log-group"
    error_message = "name output should match the configured name."
  }
}
