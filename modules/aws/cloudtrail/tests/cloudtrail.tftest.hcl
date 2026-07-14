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
    include_global_service_events = false
    is_multi_region_trail         = false
    enable_log_file_validation    = false
    key_deletion_window_in_days   = 10
    key_enable_key_rotation       = false
    versioning_status             = "Suspended"
    sse_algorithm                 = "AES256"
    cloudwatch_retention_in_days  = 30
    force_destroy                 = true
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
    condition     = aws_cloudtrail.cloudtrail.enable_log_file_validation == false
    error_message = "enable_log_file_validation override should be honored."
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
    condition     = aws_s3_bucket_versioning.cloudtrail_bucket_versioning.versioning_configuration[0].status == "Suspended"
    error_message = "versioning_status override should be honored."
  }

  assert {
    condition     = [for r in aws_s3_bucket_server_side_encryption_configuration.cloudtrail_bucket_encryption.rule : r.apply_server_side_encryption_by_default[0].sse_algorithm][0] == "AES256"
    error_message = "sse_algorithm override should be honored."
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
    condition     = output.s3_bucket_id != null
    error_message = "s3_bucket_id output should be populated."
  }

  assert {
    condition     = output.s3_bucket_arn != null
    error_message = "s3_bucket_arn output should be populated."
  }

  assert {
    condition     = output.s3_bucket_domain_name != null
    error_message = "s3_bucket_domain_name output should be populated."
  }

  assert {
    condition     = output.hosted_zone_id != null
    error_message = "hosted_zone_id output should be populated."
  }

  assert {
    condition     = output.cloudtrail_id != null
    error_message = "cloudtrail_id output should be populated."
  }

  assert {
    condition     = output.cloudtrail_home_region != null
    error_message = "cloudtrail_home_region output should be populated."
  }

  assert {
    condition     = output.cloudtrail_arn != null
    error_message = "cloudtrail_arn output should be populated."
  }
}
