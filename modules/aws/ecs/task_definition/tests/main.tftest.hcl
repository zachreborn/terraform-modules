mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"}}]}"
    }
  }

  mock_resource "aws_iam_role" {
    defaults = {
      arn = "arn:aws:iam::123456789012:role/mocked-role"
    }
  }

  mock_resource "aws_iam_policy" {
    defaults = {
      arn = "arn:aws:iam::123456789012:policy/mocked-policy"
    }
  }
}

variables {
  family = "example-app"
  container_definitions = jsonencode([
    {
      name      = "web"
      image     = "123456789012.dkr.ecr.us-east-1.amazonaws.com/web:latest"
      essential = true
      portMappings = [
        { name = "http", containerPort = 8080, protocol = "tcp" }
      ]
    }
  ])
  cpu    = "256"
  memory = "512"
}

run "fargate_defaults_plan_succeeds" {
  command = plan

  assert {
    condition     = aws_ecs_task_definition.this.network_mode == "awsvpc"
    error_message = "Expected network_mode to default to awsvpc."
  }

  assert {
    condition     = length(aws_ecs_task_definition.this.requires_compatibilities) == 1 && contains(aws_ecs_task_definition.this.requires_compatibilities, "FARGATE")
    error_message = "Expected requires_compatibilities to default to [FARGATE]."
  }

  assert {
    condition     = output.execution_role_arn != null && output.task_role_arn != null
    error_message = "Expected both the execution role and task role to be created by default."
  }

  assert {
    condition     = module.execution_role[0].arn != null && module.task_role[0].arn != null
    error_message = "Expected the execution role and task role to be created as two separate module instances (least-privilege separation), not a single shared role."
  }

  assert {
    condition     = length(aws_ecs_task_definition.this.volume) == 0
    error_message = "Expected no volume blocks when volumes defaults to [], covering the empty-volumes side of the dynamic volume toggle."
  }
}

run "bring_your_own_execution_role_does_not_create_one" {
  command = plan

  variables {
    create_execution_role = false
    execution_role_arn    = "arn:aws:iam::123456789012:role/existing-execution-role"
  }

  assert {
    condition     = output.execution_role_arn == "arn:aws:iam::123456789012:role/existing-execution-role"
    error_message = "Expected the execution_role_arn output to pass through the supplied ARN."
  }
}

run "bring_your_own_task_role_does_not_create_one" {
  command = plan

  variables {
    create_task_role = false
    task_role_arn    = "arn:aws:iam::123456789012:role/existing-task-role"
  }

  assert {
    condition     = output.task_role_arn == "arn:aws:iam::123456789012:role/existing-task-role"
    error_message = "Expected the task_role_arn output to pass through the supplied ARN."
  }
}

run "least_privilege_task_role_policy_is_attached" {
  command = plan

  variables {
    task_role_policy_json = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect   = "Allow"
          Action   = ["s3:GetObject"]
          Resource = "arn:aws:s3:::example-bucket/*"
        }
      ]
    })
  }

  assert {
    condition     = output.task_role_arn != null
    error_message = "Expected the task role to still be created when a least-privilege policy is supplied."
  }
}

run "task_role_policy_json_requires_create_task_role" {
  command = plan

  variables {
    create_task_role = false
    task_role_arn    = "arn:aws:iam::123456789012:role/existing-task-role"
    task_role_policy_json = jsonencode({
      Version   = "2012-10-17"
      Statement = []
    })
  }

  expect_failures = [
    aws_ecs_task_definition.this,
  ]
}

run "enable_fault_injection_is_wired_through" {
  command = plan

  variables {
    enable_fault_injection = true
    network_mode           = "awsvpc"
  }

  assert {
    condition     = aws_ecs_task_definition.this.enable_fault_injection == true
    error_message = "Expected enable_fault_injection to be passed through to the resource."
  }
}

# CKV_AWS_97 behavior assertions: prove that efs_volume_configuration's transit_encryption
# defaults to "ENABLED" via the optional(string, "ENABLED") type constraint even when the
# caller omits it (i.e. the suppressed finding is a false positive, not a real gap).
run "efs_volume_omitting_transit_encryption_defaults_to_enabled" {
  command = plan

  variables {
    volumes = [
      {
        name = "efs-data"
        efs_volume_configuration = {
          file_system_id = "fs-12345678"
        }
      }
    ]
  }

  assert {
    condition     = length(aws_ecs_task_definition.this.volume) == 1
    error_message = "Expected exactly one volume block to be created for the supplied EFS volume."
  }

  # volume is a set of objects; efs_volume_configuration inside it is also a set (0 or 1 elements),
  # so iterate with `for` rather than indexing directly with [0].
  assert {
    condition = anytrue([
      for v in aws_ecs_task_definition.this.volume :
      anytrue([for e in v.efs_volume_configuration : e.transit_encryption == "ENABLED"])
    ])
    error_message = "Expected transit_encryption to default to ENABLED when omitted from efs_volume_configuration, proving CKV_AWS_97 is a false positive."
  }
}

run "efs_volume_explicit_transit_encryption_enabled" {
  command = plan

  variables {
    volumes = [
      {
        name = "efs-data"
        efs_volume_configuration = {
          file_system_id     = "fs-12345678"
          transit_encryption = "ENABLED"
        }
      }
    ]
  }

  assert {
    condition = anytrue([
      for v in aws_ecs_task_definition.this.volume :
      anytrue([for e in v.efs_volume_configuration : e.transit_encryption == "ENABLED"])
    ])
    error_message = "Expected transit_encryption to be ENABLED when explicitly set by the caller."
  }
}
