mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
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
