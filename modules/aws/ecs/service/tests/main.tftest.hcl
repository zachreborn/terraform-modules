mock_provider "aws" {}

variables {
  name                = "example-app"
  cluster_arn         = "arn:aws:ecs:us-east-1:123456789012:cluster/example-app"
  task_definition_arn = "arn:aws:ecs:us-east-1:123456789012:task-definition/example-app:1"
  subnet_ids          = ["subnet-aaaa1111", "subnet-bbbb2222"]
}

run "managed_desired_count_baseline" {
  command = plan

  assert {
    condition     = length(aws_ecs_service.this) == 1
    error_message = "Expected aws_ecs_service.this to be created when ignore_desired_count is false."
  }

  assert {
    condition     = length(aws_ecs_service.ignore_desired_count) == 0
    error_message = "Expected aws_ecs_service.ignore_desired_count to not be created when ignore_desired_count is false."
  }

  assert {
    condition     = output.name == "example-app"
    error_message = "Expected the name output to resolve via the managed-desired-count resource."
  }

  assert {
    condition     = output.cluster != null
    error_message = "Expected the cluster output to resolve via the managed-desired-count resource."
  }
}

run "ignore_desired_count_uses_the_other_resource" {
  command = plan

  variables {
    ignore_desired_count = true
  }

  assert {
    condition     = length(aws_ecs_service.this) == 0
    error_message = "Expected aws_ecs_service.this to not be created when ignore_desired_count is true."
  }

  assert {
    condition     = length(aws_ecs_service.ignore_desired_count) == 1
    error_message = "Expected aws_ecs_service.ignore_desired_count to be created when ignore_desired_count is true."
  }

  assert {
    condition     = output.name == "example-app"
    error_message = "Expected the name output to still resolve via the ignore-desired-count resource."
  }
}

run "create_security_group_wires_into_network_configuration" {
  command = plan

  variables {
    create_security_group = true
    vpc_id                = "vpc-abcd1234"
  }

  assert {
    condition     = output.security_group_id != null
    error_message = "Expected a security group to be created and its id output when create_security_group is true."
  }

  assert {
    condition     = contains(aws_ecs_service.this[0].network_configuration[0].security_groups, output.security_group_id)
    error_message = "Expected the created security group id to be included in the service's network_configuration."
  }
}

run "load_balancer_entry_produces_one_block" {
  command = plan

  variables {
    load_balancers = [
      {
        target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/example/abcd1234"
        container_name   = "web"
        container_port   = 8080
      }
    ]
  }

  assert {
    condition     = length(aws_ecs_service.this[0].load_balancer) == 1
    error_message = "Expected exactly one load_balancer block when one entry is supplied."
  }
}

run "launch_type_and_capacity_provider_strategy_are_mutually_exclusive" {
  command = plan

  variables {
    launch_type = "FARGATE"
    capacity_provider_strategy = [
      { capacity_provider = "FARGATE", base = 1, weight = 100 }
    ]
  }

  expect_failures = [
    aws_ecs_service.this,
  ]
}

run "create_security_group_without_vpc_id_fails_fast" {
  command = plan

  variables {
    create_security_group = true
  }

  expect_failures = [
    aws_ecs_service.this,
  ]
}

run "daemon_scheduling_strategy_omits_desired_count_and_max_percent" {
  command = plan

  variables {
    scheduling_strategy = "DAEMON"
  }

  assert {
    condition     = aws_ecs_service.this[0].desired_count == null
    error_message = "Expected desired_count to be omitted for DAEMON scheduling strategy."
  }

  assert {
    condition     = aws_ecs_service.this[0].deployment_maximum_percent == null
    error_message = "Expected deployment_maximum_percent to be omitted for DAEMON scheduling strategy."
  }
}

run "omitting_subnet_ids_omits_network_configuration" {
  command = plan

  variables {
    subnet_ids = null
  }

  assert {
    condition     = length(aws_ecs_service.this[0].network_configuration) == 0
    error_message = "Expected network_configuration to be omitted entirely when subnet_ids is null (bridge/host/none network mode)."
  }
}

run "code_deploy_controller_omits_deployment_circuit_breaker" {
  command = plan

  variables {
    deployment_controller_type = "CODE_DEPLOY"
  }

  assert {
    condition     = length(aws_ecs_service.this[0].deployment_circuit_breaker) == 0
    error_message = "Expected deployment_circuit_breaker to be omitted for the CODE_DEPLOY controller, even though enable_deployment_circuit_breaker defaults to true."
  }
}
