# Offline only: mock computed attributes, never configured inputs.
mock_provider "aws" {
  mock_resource "aws_lambda_event_source_mapping" {
    defaults = {
      id                      = "00000000-0000-0000-0000-000000000537"
      uuid                    = "00000000-0000-0000-0000-000000000537"
      arn                     = "arn:aws:lambda:us-east-1:123456789012:event-source-mapping:00000000-0000-0000-0000-000000000537"
      function_arn            = "arn:aws:lambda:us-east-1:123456789012:function:worker"
      state                   = "Enabled"
      state_transition_reason = "USER_INITIATED"
      last_modified           = "2026-01-01T00:00:00Z"
      last_processing_result  = "OK"
      tags_all                = { Name = "worker" }
    }
  }
}

variables {
  function_name    = "worker"
  event_source_arn = "arn:aws:sqs:us-east-1:123456789012:work"
}



run "rejects_topics_cardinality" {
  command = plan
  variables {
    topics = ["one", "two"]
  }
  expect_failures = [var.topics]
}

run "rejects_topics_empty" {
  command = plan
  variables {
    topics = [""]
  }
  expect_failures = [var.topics]
}

run "rejects_topics_length" {
  command = plan
  variables {
    topics = ["xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"]
  }
  expect_failures = [var.topics]
}

run "rejects_topics_null" {
  command = plan
  variables {
    topics = [null]
  }
  expect_failures = [var.topics]
}

run "rejects_source_access_count" {
  command = plan
  variables {
    source_access_configuration = [{ type = "VPC_SUBNET", uri = "subnet:subnet-00000000" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000001" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000002" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000003" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000004" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000005" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000006" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000007" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000008" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000009" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000010" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000011" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000012" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000013" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000014" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000015" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000016" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000017" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000018" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000019" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000020" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000021" }, { type = "VPC_SUBNET", uri = "subnet:subnet-00000022" }]
  }
  expect_failures = [var.source_access_configuration]
}

run "rejects_source_access_enum" {
  command = plan
  variables {
    source_access_configuration = [{ type = "BAD", uri = "fake" }]
  }
  expect_failures = [var.source_access_configuration]
}

run "rejects_filter_count" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"body\": {\"n\": [0]}}" }, { pattern = "{\"body\": {\"n\": [1]}}" }, { pattern = "{\"body\": {\"n\": [2]}}" }, { pattern = "{\"body\": {\"n\": [3]}}" }, { pattern = "{\"body\": {\"n\": [4]}}" }, { pattern = "{\"body\": {\"n\": [5]}}" }, { pattern = "{\"body\": {\"n\": [6]}}" }, { pattern = "{\"body\": {\"n\": [7]}}" }, { pattern = "{\"body\": {\"n\": [8]}}" }, { pattern = "{\"body\": {\"n\": [9]}}" }, { pattern = "{\"body\": {\"n\": [10]}}" }] }
  }
  expect_failures = [var.filter_criteria]
}

run "rejects_filter_json" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{broken" }] }
  }
  expect_failures = [var.filter_criteria]
}

run "rejects_filter_length" {
  command = plan
  variables {
    filter_criteria = { filter = [{ pattern = "{\"x\": \"aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\"}" }] }
  }
  expect_failures = [var.filter_criteria]
}

run "rejects_metrics_empty" {
  command = plan
  variables {
    metrics_config = { metrics = [] }
  }
  expect_failures = [var.metrics_config]
}