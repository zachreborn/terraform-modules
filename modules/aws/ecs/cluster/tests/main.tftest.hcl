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

  assert {
    condition     = anytrue([for s in data.aws_iam_policy_document.kms[0].statement : s.sid == "AllowFargateGenerateDataKey"])
    error_message = "Expected the KMS key policy to grant fargate.amazonaws.com the GenerateDataKeyWithoutPlaintext permission needed for Fargate ephemeral storage encryption when this CMK is the default managed-storage key."
  }

  assert {
    condition     = anytrue([for s in data.aws_iam_policy_document.kms[0].statement : s.sid == "AllowFargateCreateGrant"])
    error_message = "Expected the KMS key policy to grant fargate.amazonaws.com the CreateGrant permission needed for Fargate ephemeral storage encryption."
  }

  # CKV_AWS_224 behavior assertions: prove that, under module defaults, the exec-command
  # configuration is genuinely CMK-backed and CloudWatch-encrypted (i.e. the suppressed
  # finding is a false positive, not a real gap).
  assert {
    condition     = aws_ecs_cluster.this.configuration[0].execute_command_configuration[0].kms_key_id != null
    error_message = "Expected execute_command_configuration.kms_key_id to be set by default (CMK-backed exec-command logging), proving CKV_AWS_224 is a false positive."
  }

  assert {
    condition     = aws_ecs_cluster.this.configuration[0].execute_command_configuration[0].log_configuration[0].cloud_watch_encryption_enabled == true
    error_message = "Expected log_configuration.cloud_watch_encryption_enabled to be true by default, proving CKV_AWS_224 is a false positive."
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

  assert {
    condition     = length(aws_ecs_cluster.this.configuration[0].execute_command_configuration) == 0
    error_message = "Expected execute_command_configuration block to be absent when enable_execute_command_logging is false, proving the dynamic block guard works correctly."
  }
}
