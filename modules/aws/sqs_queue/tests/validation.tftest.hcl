mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
}

run "allow_policy_null_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = null })
  }
  expect_failures = [var.redrive_allow_policy]
}

run "redrive_invalid_arn" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = "not-an-arn", maxReceiveCount = 4 })
  }
  expect_failures = [var.redrive_policy]
}

run "allow_policy_object_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = { first = "arn:aws:sqs:us-east-1:123456789012:q" } })
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_string_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = "arn:aws:sqs:us-east-1:123456789012:q" })
  }
  expect_failures = [var.redrive_allow_policy]
}

run "redrive_null_arn" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = null, maxReceiveCount = 4 })
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_count_minimum" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = "arn:aws:sqs:us-east-1:123456789012:dlq", maxReceiveCount = 1 })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_policy).maxReceiveCount == 1
    error_message = "One delivery must remain accepted."
  }
}

run "redrive_count_maximum" {
  command = plan
  variables {
    redrive_policy = jsonencode({ deadLetterTargetArn = "arn:aws:sqs:us-east-1:123456789012:dlq", maxReceiveCount = 1000 })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_policy).maxReceiveCount == 1000
    error_message = "1000 deliveries must remain accepted."
  }
}

run "allow_policy_ten_sources" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = [for i in range(10) : "arn:aws:sqs:us-east-1:123456789012:q${i}"] })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_allow_policy).sourceQueueArns == [for i in range(10) : "arn:aws:sqs:us-east-1:123456789012:q${i}"]
    error_message = "Ten source queue ARNs must be accepted and retained exactly."
  }
}

run "legacy_key_spec_unused" {
  command = plan
  variables {
    key_customer_master_key_spec = "ECC_NIST_P256"
    key_usage                    = "SIGN_VERIFY"
  }
  assert {
    condition     = length(module.kms) == 0
    error_message = "Unused legacy KMS options must not restrict a non-KMS queue."
  }
}

run "delay_seconds_below" {
  command = plan
  variables {
    delay_seconds = -1
  }
  expect_failures = [var.delay_seconds]
}

run "delay_seconds_above" {
  command = plan
  variables {
    delay_seconds = 901
  }
  expect_failures = [var.delay_seconds]
}

run "delay_seconds_fractional" {
  command = plan
  variables {
    delay_seconds = 0.5
  }
  expect_failures = [var.delay_seconds]
}

run "delay_seconds_minimum" {
  command = plan
  variables {
    delay_seconds = 0
  }
  assert {
    condition     = aws_sqs_queue.queue.delay_seconds == 0
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "delay_seconds_maximum" {
  command = plan
  variables {
    delay_seconds = 900
  }
  assert {
    condition     = aws_sqs_queue.queue.delay_seconds == 900
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "visibility_timeout_seconds_below" {
  command = plan
  variables {
    visibility_timeout_seconds = -1
  }
  expect_failures = [var.visibility_timeout_seconds]
}

run "visibility_timeout_seconds_above" {
  command = plan
  variables {
    visibility_timeout_seconds = 43201
  }
  expect_failures = [var.visibility_timeout_seconds]
}

run "visibility_timeout_seconds_fractional" {
  command = plan
  variables {
    visibility_timeout_seconds = 0.5
  }
  expect_failures = [var.visibility_timeout_seconds]
}

run "visibility_timeout_seconds_minimum" {
  command = plan
  variables {
    visibility_timeout_seconds = 0
  }
  assert {
    condition     = aws_sqs_queue.queue.visibility_timeout_seconds == 0
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "visibility_timeout_seconds_maximum" {
  command = plan
  variables {
    visibility_timeout_seconds = 43200
  }
  assert {
    condition     = aws_sqs_queue.queue.visibility_timeout_seconds == 43200
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "message_retention_seconds_below" {
  command = plan
  variables {
    message_retention_seconds = 59
  }
  expect_failures = [var.message_retention_seconds]
}

run "message_retention_seconds_above" {
  command = plan
  variables {
    message_retention_seconds = 1209601
  }
  expect_failures = [var.message_retention_seconds]
}

run "message_retention_seconds_fractional" {
  command = plan
  variables {
    message_retention_seconds = 60.5
  }
  expect_failures = [var.message_retention_seconds]
}

run "message_retention_seconds_minimum" {
  command = plan
  variables {
    message_retention_seconds = 60
  }
  assert {
    condition     = aws_sqs_queue.queue.message_retention_seconds == 60
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "message_retention_seconds_maximum" {
  command = plan
  variables {
    message_retention_seconds = 1209600
  }
  assert {
    condition     = aws_sqs_queue.queue.message_retention_seconds == 1209600
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "kms_data_key_reuse_period_seconds_below" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 59
  }
  expect_failures = [var.kms_data_key_reuse_period_seconds]
}

run "kms_data_key_reuse_period_seconds_above" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 86401
  }
  expect_failures = [var.kms_data_key_reuse_period_seconds]
}

run "kms_data_key_reuse_period_seconds_fractional" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 60.5
  }
  expect_failures = [var.kms_data_key_reuse_period_seconds]
}

run "kms_data_key_reuse_period_seconds_minimum" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 60
    kms_master_key_id                 = "alias/aws/sqs"
  }
  assert {
    condition     = aws_sqs_queue.queue.kms_data_key_reuse_period_seconds == 60
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "kms_data_key_reuse_period_seconds_maximum" {
  command = plan
  variables {
    kms_data_key_reuse_period_seconds = 86400
    kms_master_key_id                 = "alias/aws/sqs"
  }
  assert {
    condition     = aws_sqs_queue.queue.kms_data_key_reuse_period_seconds == 86400
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "max_message_size_below" {
  command = plan
  variables {
    max_message_size = 1023
  }
  expect_failures = [var.max_message_size]
}

run "max_message_size_above" {
  command = plan
  variables {
    max_message_size = 1048577
  }
  expect_failures = [var.max_message_size]
}

run "max_message_size_fractional" {
  command = plan
  variables {
    max_message_size = 1024.5
  }
  expect_failures = [var.max_message_size]
}

run "max_message_size_minimum" {
  command = plan
  variables {
    max_message_size = 1024
  }
  assert {
    condition     = aws_sqs_queue.queue.max_message_size == 1024
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "max_message_size_maximum" {
  command = plan
  variables {
    max_message_size = 1048576
  }
  assert {
    condition     = aws_sqs_queue.queue.max_message_size == 1048576
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "receive_wait_time_seconds_below" {
  command = plan
  variables {
    receive_wait_time_seconds = -1
  }
  expect_failures = [var.receive_wait_time_seconds]
}

run "receive_wait_time_seconds_above" {
  command = plan
  variables {
    receive_wait_time_seconds = 21
  }
  expect_failures = [var.receive_wait_time_seconds]
}

run "receive_wait_time_seconds_fractional" {
  command = plan
  variables {
    receive_wait_time_seconds = 0.5
  }
  expect_failures = [var.receive_wait_time_seconds]
}

run "receive_wait_time_seconds_minimum" {
  command = plan
  variables {
    receive_wait_time_seconds = 0
  }
  assert {
    condition     = aws_sqs_queue.queue.receive_wait_time_seconds == 0
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "receive_wait_time_seconds_maximum" {
  command = plan
  variables {
    receive_wait_time_seconds = 20
  }
  assert {
    condition     = aws_sqs_queue.queue.receive_wait_time_seconds == 20
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "key_deletion_window_in_days_below" {
  command = plan
  variables {
    key_deletion_window_in_days = 6
  }
  expect_failures = [var.key_deletion_window_in_days]
}

run "key_deletion_window_in_days_above" {
  command = plan
  variables {
    key_deletion_window_in_days = 31
  }
  expect_failures = [var.key_deletion_window_in_days]
}

run "key_deletion_window_in_days_fractional" {
  command = plan
  variables {
    key_deletion_window_in_days = 7.5
  }
  expect_failures = [var.key_deletion_window_in_days]
}

run "key_deletion_window_in_days_minimum" {
  command = plan
  variables {
    key_deletion_window_in_days = 7
    create_kms_key              = true
    key_policy                  = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  assert {
    condition     = module.kms[0].deletion_window_in_days == 7
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "key_deletion_window_in_days_maximum" {
  command = plan
  variables {
    key_deletion_window_in_days = 30
    create_kms_key              = true
    key_policy                  = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  assert {
    condition     = module.kms[0].deletion_window_in_days == 30
    error_message = "Inclusive valid numeric boundary must be wired unchanged."
  }
}

run "policy_malformed" {
  command = plan
  variables {
    policy = "not-json"
  }
  expect_failures = [var.policy]
}

run "key_policy_malformed" {
  command = plan
  variables {
    key_policy = "not-json"
  }
  expect_failures = [var.key_policy]
}

run "redrive_policy_malformed" {
  command = plan
  variables {
    redrive_policy = "not-json"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_allow_policy_malformed" {
  command = plan
  variables {
    redrive_allow_policy = "not-json"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "policy_missing_version" {
  command = plan
  variables {
    policy = "{\"Statement\": []}"
  }
  expect_failures = [var.policy]
}

run "policy_wrong_version" {
  command = plan
  variables {
    policy = "{\"Version\": \"2008-10-17\", \"Statement\": []}"
  }
  expect_failures = [var.policy]
}

run "redrive_missing_dlq" {
  command = plan
  variables {
    redrive_policy = "{\"maxReceiveCount\": 4}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_empty_dlq" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"\", \"maxReceiveCount\": 4}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_missing_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\"}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_string_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": \"4\"}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_fractional_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": 1.5}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_zero_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": 0}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_large_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": 1001}"
  }
  expect_failures = [var.redrive_policy]
}

run "redrive_null_receive_count" {
  command = plan
  variables {
    redrive_policy = "{\"deadLetterTargetArn\": \"arn:aws:sqs:us-east-1:123456789012:dlq\", \"maxReceiveCount\": null}"
  }
  expect_failures = [var.redrive_policy]
}

run "allow_policy_bad_permission" {
  command = plan
  variables {
    redrive_allow_policy = "{\"redrivePermission\": \"no\"}"
  }
  expect_failures = [var.redrive_allow_policy]
}

run "allow_policy_missing_permission" {
  command = plan
  variables {
    redrive_allow_policy = "{}"
  }
  expect_failures = [var.redrive_allow_policy]
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

run "name_conflict" {
  command = plan
  variables {
    name_prefix = "prefix"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "fifo_missing_suffix" {
  command = plan
  variables {
    fifo_queue = true
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "standard_fifo_suffix" {
  command = plan
  variables {
    name = "work.fifo"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "standard_content_dedup" {
  command = plan
  variables {
    content_based_deduplication = true
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "standard_dedup_scope" {
  command = plan
  variables {
    deduplication_scope = "queue"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "standard_throughput" {
  command = plan
  variables {
    fifo_throughput_limit = "perQueue"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "high_throughput_without_group" {
  command = plan
  variables {
    name                  = "work.fifo"
    fifo_queue            = true
    fifo_throughput_limit = "perMessageGroupId"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "high_throughput_queue_scope" {
  command = plan
  variables {
    name                  = "work.fifo"
    fifo_queue            = true
    deduplication_scope   = "queue"
    fifo_throughput_limit = "perMessageGroupId"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "created_existing_conflict" {
  command = plan
  variables {
    create_kms_key    = true
    kms_master_key_id = "alias/aws/sqs"
    key_policy        = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "created_sse_true" {
  command = plan
  variables {
    create_kms_key          = true
    sqs_managed_sse_enabled = true
    key_policy              = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "created_sse_false" {
  command = plan
  variables {
    create_kms_key          = true
    sqs_managed_sse_enabled = false
    key_policy              = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "external_sse_true" {
  command = plan
  variables {
    kms_master_key_id       = "alias/aws/sqs"
    sqs_managed_sse_enabled = true
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "external_sse_false" {
  command = plan
  variables {
    kms_master_key_id       = "alias/aws/sqs"
    sqs_managed_sse_enabled = false
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "asymmetric_key" {
  command = plan
  variables {
    create_kms_key               = true
    key_customer_master_key_spec = "RSA_2048"
    key_enable_key_rotation      = false
    key_policy                   = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  expect_failures = [aws_sqs_queue.queue]
}

run "wrong_key_usage" {
  command = plan
  variables {
    create_kms_key = true
    key_usage      = "SIGN_VERIFY"
    key_policy     = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
  expect_failures = [aws_sqs_queue.queue]
}
