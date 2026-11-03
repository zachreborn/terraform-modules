mock_provider "aws" {}

# Scalar type conversion errors (for example visibility = "invalid") occur
# before variable validation; they are not represented as expect_failures.

variables {
  name           = "work"
  create_kms_key = false
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