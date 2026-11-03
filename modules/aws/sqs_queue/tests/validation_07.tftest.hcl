mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}



run "allow_policy_missing_sources" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"byQueue\"}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_empty_sources" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"byQueue\", \"sourceQueueArns\": []}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_too_many_sources" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"byQueue\", \"sourceQueueArns\": [\"arn:aws:sqs:us-east-1:123456789012:q0\", \"arn:aws:sqs:us-east-1:123456789012:q1\", \"arn:aws:sqs:us-east-1:123456789012:q2\", \"arn:aws:sqs:us-east-1:123456789012:q3\", \"arn:aws:sqs:us-east-1:123456789012:q4\", \"arn:aws:sqs:us-east-1:123456789012:q5\", \"arn:aws:sqs:us-east-1:123456789012:q6\", \"arn:aws:sqs:us-east-1:123456789012:q7\", \"arn:aws:sqs:us-east-1:123456789012:q8\", \"arn:aws:sqs:us-east-1:123456789012:q9\", \"arn:aws:sqs:us-east-1:123456789012:q10\"]}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_invalid_source_arn" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"byQueue\", \"sourceQueueArns\": [\"not-an-arn\"]}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_allowall_sources" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"allowAll\", \"sourceQueueArns\": []}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_denyall_sources" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"denyAll\", \"sourceQueueArns\": []}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "deduplication_scope_invalid" {
  command = plan
  variables {
    deduplication_scope = "invalid"
  }
  expect_failures = [var.deduplication_scope]
}

run "fifo_throughput_limit_invalid" {
  command = plan
  variables {
    fifo_throughput_limit = "invalid"
  }
  expect_failures = [var.fifo_throughput_limit]
}

run "key_name_prefix_invalid" {
  command = plan
  variables {
    key_name_prefix = "work"
  }
  expect_failures = [var.key_name_prefix]
}

run "key_customer_master_key_spec_invalid" {
  command = plan
  variables {
    key_customer_master_key_spec = "invalid"
  }
  expect_failures = [var.key_customer_master_key_spec]
}