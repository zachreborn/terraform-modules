mock_provider "aws" {
  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:key/abcd1234-a123-456a-a12b-a123b4cd56ef"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/test-policy"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn  = "arn:aws:iam::123456789012:role/test-role"
      name = "test-role"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:test-log-group"
    }
  }
}

run "valid_baseline_plans_successfully" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.name == "cloudtrail"
    error_message = "name should default to 'cloudtrail'."
  }

  assert {
    condition     = aws_s3_bucket.cloudtrail_s3_bucket.bucket_prefix == "cloudtrail-"
    error_message = "The S3 bucket prefix should be derived from var.name."
  }
}

run "field_defaults_are_applied" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.include_global_service_events == true
    error_message = "include_global_service_events should default to true."
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.is_multi_region_trail == true
    error_message = "is_multi_region_trail should default to true."
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.is_organization_trail == false
    error_message = "is_organization_trail should default to false."
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.enable_log_file_validation == true
    error_message = "enable_log_file_validation should default to true."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.deletion_window_in_days == 30
    error_message = "key_deletion_window_in_days should default to 30."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.enable_key_rotation == true
    error_message = "key_enable_key_rotation should default to true."
  }

  assert {
    condition     = aws_s3_bucket_versioning.cloudtrail_bucket_versioning.versioning_configuration[0].status == "Enabled"
    error_message = "versioning_status should default to Enabled."
  }

  assert {
    condition     = [for r in aws_s3_bucket_server_side_encryption_configuration.cloudtrail_bucket_encryption.rule : r.apply_server_side_encryption_by_default[0].sse_algorithm][0] == "aws:kms"
    error_message = "sse_algorithm should default to aws:kms."
  }

  assert {
    condition     = aws_cloudwatch_log_group.cloudtrail.retention_in_days == 90
    error_message = "cloudwatch_retention_in_days should default to 90."
  }

  assert {
    condition     = aws_s3_bucket.cloudtrail_s3_bucket.force_destroy == false
    error_message = "force_destroy should default to false."
  }
}

run "field_overrides_are_honored" {
  command = plan

  variables {
    name                          = "custom-trail"
    target_bucket                 = "test-cloudtrail-logging-target"
    target_prefix                 = "custom-log-prefix/"
    include_global_service_events = false
    is_multi_region_trail         = false
    is_organization_trail         = true
    enable_log_file_validation    = false
    key_customer_master_key_spec  = "RSA_2048"
    key_description               = "Custom CloudTrail KMS key description"
    key_deletion_window_in_days   = 10
    key_enable_key_rotation       = false
    # key_usage's validation only accepts "ENCRYPT_DECRYPT" -- there is no distinct valid
    # value to override to, so this is set explicitly (matching the default) purely to prove
    # the wiring holds alongside every other overridden argument in this run.
    key_usage                        = "ENCRYPT_DECRYPT"
    key_is_enabled                   = "false"
    bucket_lifecycle_rule_id         = "custom_lifecycle_rule"
    bucket_lifecycle_expiration_days = 180
    versioning_status                = "Suspended"
    bucket_key_enabled               = false
    sse_algorithm                    = "AES256"
    mfa_delete                       = "Enabled"
    cloudwatch_retention_in_days     = 30
    force_destroy                    = true
    iam_policy_description           = "Custom IAM policy description"
    iam_policy_name_prefix           = "custom_policy_prefix_"
    iam_policy_path                  = "/custom-path/"
    iam_role_assume_role_policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "CustomAssumeRole"
          Effect    = "Allow"
          Principal = { Service = "cloudtrail.amazonaws.com" }
          Action    = "sts:AssumeRole"
        }
      ]
    })
    iam_role_description           = "Custom IAM role description"
    iam_role_force_detach_policies = true
    iam_role_max_session_duration  = 7200
    iam_role_name_prefix           = "custom_role_prefix_"
    iam_role_permissions_boundary  = "arn:aws:iam::123456789012:policy/permissions-boundary"
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.name == "custom-trail"
    error_message = "name override should be honored."
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.include_global_service_events == false
    error_message = "include_global_service_events override should be honored."
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.is_multi_region_trail == false
    error_message = "is_multi_region_trail override should be honored."
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.is_organization_trail == true
    error_message = "is_organization_trail override should be honored."
  }

  assert {
    condition     = aws_cloudtrail.cloudtrail.enable_log_file_validation == false
    error_message = "enable_log_file_validation override should be honored."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.customer_master_key_spec == "RSA_2048"
    error_message = "key_customer_master_key_spec override should be honored."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.description == "Custom CloudTrail KMS key description"
    error_message = "key_description override should be honored."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.deletion_window_in_days == 10
    error_message = "key_deletion_window_in_days override should be honored."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.enable_key_rotation == false
    error_message = "key_enable_key_rotation override should be honored."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.key_usage == "ENCRYPT_DECRYPT"
    error_message = "key_usage should be wired through even though it has only one valid value."
  }

  assert {
    condition     = aws_kms_key.cloudtrail.is_enabled == false
    error_message = "key_is_enabled override should be honored."
  }

  assert {
    condition     = [for r in aws_s3_bucket_lifecycle_configuration.cloudtrail_bucket_lifecycle.rule : r.id][0] == "custom_lifecycle_rule"
    error_message = "bucket_lifecycle_rule_id override should be honored."
  }

  assert {
    condition     = [for r in aws_s3_bucket_lifecycle_configuration.cloudtrail_bucket_lifecycle.rule : r.expiration[0].days][0] == 180
    error_message = "bucket_lifecycle_expiration_days override should be honored."
  }

  assert {
    condition     = aws_s3_bucket_versioning.cloudtrail_bucket_versioning.versioning_configuration[0].status == "Suspended"
    error_message = "versioning_status override should be honored."
  }

  assert {
    condition     = [for r in aws_s3_bucket_server_side_encryption_configuration.cloudtrail_bucket_encryption.rule : r.bucket_key_enabled][0] == false
    error_message = "bucket_key_enabled override should be honored."
  }

  assert {
    condition     = [for r in aws_s3_bucket_server_side_encryption_configuration.cloudtrail_bucket_encryption.rule : r.apply_server_side_encryption_by_default[0].sse_algorithm][0] == "AES256"
    error_message = "sse_algorithm override should be honored."
  }

  assert {
    condition     = aws_s3_bucket_versioning.cloudtrail_bucket_versioning.versioning_configuration[0].mfa_delete == "Enabled"
    error_message = "mfa_delete override should be honored."
  }

  assert {
    condition     = aws_s3_bucket_logging.cloudtrail_s3_bucket[0].target_prefix == "custom-log-prefix/"
    error_message = "target_prefix override should be honored."
  }

  assert {
    condition     = aws_cloudwatch_log_group.cloudtrail.retention_in_days == 30
    error_message = "cloudwatch_retention_in_days override should be honored."
  }

  assert {
    condition     = aws_s3_bucket.cloudtrail_s3_bucket.force_destroy == true
    error_message = "force_destroy override should be honored."
  }

  assert {
    condition     = aws_iam_policy.cloudtrail.description == "Custom IAM policy description"
    error_message = "iam_policy_description override should be honored."
  }

  assert {
    condition     = aws_iam_policy.cloudtrail.name_prefix == "custom_policy_prefix_"
    error_message = "iam_policy_name_prefix override should be honored."
  }

  assert {
    condition     = aws_iam_policy.cloudtrail.path == "/custom-path/"
    error_message = "iam_policy_path override should be honored."
  }

  assert {
    condition = aws_iam_role.cloudtrail.assume_role_policy == jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Sid       = "CustomAssumeRole"
          Effect    = "Allow"
          Principal = { Service = "cloudtrail.amazonaws.com" }
          Action    = "sts:AssumeRole"
        }
      ]
    })
    error_message = "iam_role_assume_role_policy override should be honored."
  }

  assert {
    condition     = aws_iam_role.cloudtrail.description == "Custom IAM role description"
    error_message = "iam_role_description override should be honored."
  }

  assert {
    condition     = aws_iam_role.cloudtrail.force_detach_policies == true
    error_message = "iam_role_force_detach_policies override should be honored."
  }

  assert {
    condition     = aws_iam_role.cloudtrail.max_session_duration == 7200
    error_message = "iam_role_max_session_duration override should be honored."
  }

  assert {
    condition     = aws_iam_role.cloudtrail.name_prefix == "custom_role_prefix_"
    error_message = "iam_role_name_prefix override should be honored."
  }

  assert {
    condition     = aws_iam_role.cloudtrail.permissions_boundary == "arn:aws:iam::123456789012:policy/permissions-boundary"
    error_message = "iam_role_permissions_boundary override should be honored."
  }

  assert {
    condition     = aws_s3_bucket.cloudtrail_s3_bucket.tags["team"] == "platform"
    error_message = "Explicit tags should be honored."
  }
}

run "s3_bucket_logging_enabled_by_default_when_target_bucket_set" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
  }

  assert {
    condition     = length(aws_s3_bucket_logging.cloudtrail_s3_bucket) == 1
    error_message = "enable_s3_bucket_logging defaults to true, so the logging resource should be planned when a target_bucket is supplied."
  }

  assert {
    condition     = aws_s3_bucket_logging.cloudtrail_s3_bucket[0].target_bucket == "test-cloudtrail-logging-target"
    error_message = "target_bucket should pass through unchanged."
  }

  assert {
    condition     = aws_s3_bucket_logging.cloudtrail_s3_bucket[0].target_prefix == "log/"
    error_message = "target_prefix should default to log/."
  }
}

run "s3_bucket_logging_absent_when_disabled" {
  command = plan

  variables {
    enable_s3_bucket_logging = false
  }

  assert {
    condition     = length(aws_s3_bucket_logging.cloudtrail_s3_bucket) == 0
    error_message = "The logging resource should not be planned when enable_s3_bucket_logging is false."
  }
}

run "outputs_expose_resource_attributes" {
  command = plan

  variables {
    target_bucket = "test-cloudtrail-logging-target"
  }

  assert {
    condition     = output.s3_bucket_id == aws_s3_bucket.cloudtrail_s3_bucket.id
    error_message = "s3_bucket_id output should be wired to the S3 bucket's id."
  }

  assert {
    condition     = output.s3_bucket_arn == aws_s3_bucket.cloudtrail_s3_bucket.arn
    error_message = "s3_bucket_arn output should be wired to the S3 bucket's arn."
  }

  assert {
    condition     = output.s3_bucket_domain_name == aws_s3_bucket.cloudtrail_s3_bucket.bucket_domain_name
    error_message = "s3_bucket_domain_name output should be wired to the S3 bucket's bucket_domain_name."
  }

  assert {
    condition     = output.hosted_zone_id == aws_s3_bucket.cloudtrail_s3_bucket.hosted_zone_id
    error_message = "hosted_zone_id output should be wired to the S3 bucket's hosted_zone_id."
  }

  assert {
    condition     = output.s3_bucket_region == aws_s3_bucket.cloudtrail_s3_bucket.region
    error_message = "s3_bucket_region output should be wired to the S3 bucket's region."
  }

  assert {
    condition     = output.cloudtrail_id == aws_cloudtrail.cloudtrail.id
    error_message = "cloudtrail_id output should be wired to the trail's id."
  }

  assert {
    condition     = output.cloudtrail_home_region == aws_cloudtrail.cloudtrail.home_region
    error_message = "cloudtrail_home_region output should be wired to the trail's home_region."
  }

  assert {
    condition     = output.cloudtrail_arn == aws_cloudtrail.cloudtrail.arn
    error_message = "cloudtrail_arn output should be wired to the trail's arn."
  }
}
