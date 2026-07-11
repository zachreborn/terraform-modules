mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "fargate_defaults_plan_succeeds" {
  command = plan

  variables {
    name = "example-app"
  }

  assert {
    condition     = length(aws_ecs_cluster_capacity_providers.this.capacity_providers) == 2 && contains(aws_ecs_cluster_capacity_providers.this.capacity_providers, "FARGATE") && contains(aws_ecs_cluster_capacity_providers.this.capacity_providers, "FARGATE_SPOT")
    error_message = "Expected the cluster to default to FARGATE and FARGATE_SPOT capacity providers."
  }

  assert {
    condition     = output.kms_key_arn != null
    error_message = "Expected a CMK to be created and its ARN output by default."
  }

  assert {
    condition     = output.cloud_watch_log_group_name != null
    error_message = "Expected the exec-command CloudWatch log group to be created by default."
  }
}

run "bring_your_own_kms_key_does_not_create_one" {
  command = plan

  variables {
    name           = "example-app"
    create_kms_key = false
    kms_key_arn    = "arn:aws:kms:us-east-1:123456789012:key/abcd-1234"
  }

  assert {
    condition     = output.kms_key_arn == null
    error_message = "Expected no CMK output when create_kms_key is false; the module does not own the BYO key."
  }
}

run "bring_your_own_log_group_does_not_create_one" {
  command = plan

  variables {
    name                         = "example-app"
    create_cloud_watch_log_group = false
    cloud_watch_log_group_name   = "/aws/ecs/example-app/exec"
  }

  assert {
    condition     = output.cloud_watch_log_group_name == null
    error_message = "Expected no log group output when create_cloud_watch_log_group is false; nothing should be created via composition."
  }

  assert {
    condition     = output.cloud_watch_log_group_arn == null
    error_message = "Expected no log group ARN output when create_cloud_watch_log_group is false."
  }
}

run "disabling_execute_command_logging_skips_log_group_creation" {
  command = plan

  variables {
    name                           = "example-app"
    enable_execute_command_logging = false
  }

  assert {
    condition     = output.cloud_watch_log_group_name == null
    error_message = "Expected no log group output when enable_execute_command_logging is false, even though create_cloud_watch_log_group defaults to true."
  }
}
