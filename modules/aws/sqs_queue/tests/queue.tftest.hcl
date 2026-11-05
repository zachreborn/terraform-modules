mock_provider "aws" {
  mock_resource "aws_sqs_queue" {
    defaults = {
      id       = "https://sqs.us-east-1.amazonaws.com/123456789012/work"
      url      = "https://sqs.us-east-1.amazonaws.com/123456789012/work"
      arn      = "arn:aws:sqs:us-east-1:123456789012:work"
      tags_all = { Name = "work", Team = "platform" }
    }
  }
}

run "generated_fifo_prefix" {
  command = plan
  variables {
    name        = null
    name_prefix = "events-"
    fifo_queue  = true
  }
  assert {
    condition     = aws_sqs_queue.queue.name_prefix == "events-" && aws_sqs_queue.queue.fifo_queue && aws_sqs_queue.queue.tags.Name == "events-"
    error_message = "FIFO generated naming must preserve the prefix and type."
  }
}


variables {
  name                    = "work"
  create_kms_key          = false
  sqs_managed_sse_enabled = true
  tags                    = { Team = "platform" }
}

run "sqs_owned_work" {
  command = apply
  variables {
    visibility_timeout_seconds = "720"
    redrive_policy = jsonencode({
      deadLetterTargetArn = "arn:aws:sqs:us-east-1:123456789012:dlq"
      maxReceiveCount     = 4
    })
  }
  assert {
    condition     = length(module.kms) == 0 && length(data.aws_caller_identity.current) == 0 && length(data.aws_partition.current) == 0 && length(data.aws_region.current) == 0
    error_message = "SQS-owned encryption must create no key/alias or policy data lookups."
  }
  assert {
    condition     = aws_sqs_queue.queue.sqs_managed_sse_enabled && !aws_sqs_queue.queue.fifo_queue && aws_sqs_queue.queue.visibility_timeout_seconds == 720 && jsondecode(aws_sqs_queue.queue.redrive_policy) == { deadLetterTargetArn = "arn:aws:sqs:us-east-1:123456789012:dlq", maxReceiveCount = 4 }
    error_message = "Work queue must retain exact encryption, timing and redrive semantics."
  }
  assert {
    condition     = output.arn == "arn:aws:sqs:us-east-1:123456789012:work" && output.id == "https://sqs.us-east-1.amazonaws.com/123456789012/work" && output.url == output.id && output.name == "work" && output.tags_all == tomap({ Name = "work", Team = "platform" }) && output.kms_key_arn == null && output.kms_key_id == null && output.effective_kms_master_key_id == null
    error_message = "Every output must equal its exact provider value, with null created-key outputs."
  }
  assert {
    condition     = aws_sqs_queue.queue.tags == tomap({ Name = "work", Team = "platform" }) && aws_sqs_queue.queue.delay_seconds == 0 && aws_sqs_queue.queue.message_retention_seconds == 345600 && aws_sqs_queue.queue.max_message_size == 262144 && aws_sqs_queue.queue.receive_wait_time_seconds == 0 && aws_sqs_queue.queue.timeouts == null
    error_message = "Legacy timing/size/tag defaults and omitted timeouts must be preserved."
  }
}

run "dlq_allow_all" {
  command = plan
  variables {
    name                      = "dlq"
    message_retention_seconds = 1209600
    redrive_allow_policy      = jsonencode({ redrivePermission = "allowAll" })
  }
  assert {
    condition     = length(module.kms) == 0 && aws_sqs_queue.queue.message_retention_seconds == 1209600 && jsondecode(aws_sqs_queue.queue.redrive_allow_policy) == { redrivePermission = "allowAll" }
    error_message = "DLQ retention and allowAll permission must pass through without creating a key."
  }
}

run "dlq_deny_all" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "denyAll" })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_allow_policy) == { redrivePermission = "denyAll" }
    error_message = "denyAll must be preserved."
  }
}

run "dlq_by_queue" {
  command = plan
  variables {
    redrive_allow_policy = jsonencode({ redrivePermission = "byQueue", sourceQueueArns = ["arn:aws:sqs:us-east-1:123456789012:source"] })
  }
  assert {
    condition     = jsondecode(aws_sqs_queue.queue.redrive_allow_policy) == { redrivePermission = "byQueue", sourceQueueArns = ["arn:aws:sqs:us-east-1:123456789012:source"] }
    error_message = "byQueue sources must be forwarded unchanged."
  }
}

run "fifo_all_options" {
  command = plan
  variables {
    name                        = "events.fifo"
    fifo_queue                  = true
    content_based_deduplication = true
    deduplication_scope         = "messageGroup"
    fifo_throughput_limit       = "perMessageGroupId"
    region                      = "us-west-2"
    policy                      = jsonencode({ Version = "2012-10-17", Statement = [] })
    timeouts                    = { create = "5m", update = "6m", delete = "7m" }
    tags                        = { Name = "caller", Team = "platform" }
  }
  assert {
    condition     = aws_sqs_queue.queue.fifo_queue && aws_sqs_queue.queue.content_based_deduplication && aws_sqs_queue.queue.deduplication_scope == "messageGroup" && aws_sqs_queue.queue.fifo_throughput_limit == "perMessageGroupId" && aws_sqs_queue.queue.region == "us-west-2" && aws_sqs_queue.queue.timeouts.create == "5m" && aws_sqs_queue.queue.timeouts.update == "6m" && aws_sqs_queue.queue.timeouts.delete == "7m" && aws_sqs_queue.queue.tags == tomap({ Name = "caller", Team = "platform" }) && jsondecode(aws_sqs_queue.queue.policy) == { Version = "2012-10-17", Statement = [] }
    error_message = "FIFO options, explicit policy, region, timeout fields and caller tag overrides must all reach the queue."
  }
}

run "fifo_per_queue" {
  command = plan
  variables {
    name                  = "events.fifo"
    fifo_queue            = true
    deduplication_scope   = "queue"
    fifo_throughput_limit = "perQueue"
  }
  assert {
    condition     = aws_sqs_queue.queue.deduplication_scope == "queue" && aws_sqs_queue.queue.fifo_throughput_limit == "perQueue" && !aws_sqs_queue.queue.content_based_deduplication
    error_message = "Queue-wide FIFO controls must remain valid."
  }
}

run "explicit_encryption_disabled" {
  command = plan
  variables {
    sqs_managed_sse_enabled = false
  }
  assert {
    condition     = aws_sqs_queue.queue.sqs_managed_sse_enabled == false && output.effective_kms_master_key_id == null && length(module.kms) == 0
    error_message = "Explicit encryption disable is a caller decision and must not create a key."
  }
}

run "provider_delegation_and_nullable_options" {
  command = plan
  variables {
    name                        = null
    sqs_managed_sse_enabled     = null
    content_based_deduplication = null
    max_message_size            = null
    receive_wait_time_seconds   = null
    timeouts                    = {}
  }
  assert {
    condition     = output.effective_kms_master_key_id == null && length(module.kms) == 0 && aws_sqs_queue.queue.timeouts.create == null && aws_sqs_queue.queue.timeouts.update == null && aws_sqs_queue.queue.timeouts.delete == null && aws_sqs_queue.queue.tags.Name == "sqs"
    error_message = "Null inputs must delegate to provider defaults without empty invalid timeout values or a key."
  }
}

run "generated_prefix" {
  command = plan
  variables {
    name        = null
    name_prefix = "application-"
  }
  assert {
    condition     = aws_sqs_queue.queue.name_prefix == "application-" && aws_sqs_queue.queue.tags.Name == "application-"
    error_message = "Generated queue prefix must be forwarded with a deterministic Name tag."
  }
}
