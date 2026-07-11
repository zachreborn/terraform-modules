mock_provider "aws" {
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"sts:AssumeRole\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"}}]}"
    }
  }

  mock_resource "aws_kms_key" {
    defaults = {
      arn = "arn:aws:kms:us-east-1:123456789012:key/mocked-key"
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

  mock_resource "aws_service_discovery_http_namespace" {
    defaults = {
      arn = "arn:aws:servicediscovery:us-east-1:123456789012:http-namespace/mocked-namespace"
    }
  }
}

variables {
  cluster = {
    name = "example-app"
  }
}

run "kitchen_sink_baseline_resolves_key_to_arn" {
  command = plan

  variables {
    namespace = {
      name = "example-app"
    }

    task_definitions = {
      web = {
        cpu    = "256"
        memory = "512"
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
      }
    }

    services = {
      web = {
        task_definition = "web"
        subnet_ids      = ["subnet-aaaa1111", "subnet-bbbb2222"]
      }
    }
  }

  assert {
    condition     = output.task_definition_arns["web"] != null
    error_message = "Expected the web task definition's ARN to be exposed keyed by its logical name."
  }

  assert {
    condition     = output.service_ids["web"] != null
    error_message = "Expected the web service to resolve, proving the root module injected cluster_arn and resolved the task_definition key to an ARN automatically."
  }
}

run "multi_app_fan_out_creates_one_service_per_entry" {
  command = plan

  variables {
    task_definitions = {
      web = {
        cpu    = "256"
        memory = "512"
        container_definitions = jsonencode([
          { name = "web", image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/web:latest", essential = true }
        ])
      }
      worker = {
        cpu    = "512"
        memory = "1024"
        container_definitions = jsonencode([
          { name = "worker", image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/worker:latest", essential = true }
        ])
      }
    }

    services = {
      web = {
        task_definition = "web"
        subnet_ids      = ["subnet-aaaa1111"]
      }
      worker = {
        task_definition = "worker"
        subnet_ids      = ["subnet-aaaa1111"]
      }
    }
  }

  assert {
    condition     = length(output.service_ids) == 2
    error_message = "Expected the for_each over services to fan out into exactly two services, one per app_catalog.yaml-style entry."
  }
}

run "existing_namespace_arn_is_passed_through_without_creating_one" {
  command = plan

  variables {
    existing_namespace_arn = "arn:aws:servicediscovery:us-east-1:123456789012:http-namespace/ns-abcd1234"
  }

  assert {
    condition     = output.namespace_arn == "arn:aws:servicediscovery:us-east-1:123456789012:http-namespace/ns-abcd1234"
    error_message = "Expected namespace_arn to pass through the supplied existing_namespace_arn."
  }

  assert {
    condition     = output.namespace_id == null
    error_message = "Expected no namespace to be created when existing_namespace_arn is supplied."
  }
}

run "ec2_capacity_provider_is_created_via_composition" {
  command = plan

  variables {
    capacity_providers = {
      asg1 = {
        auto_scaling_group_arn = "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:abcd1234:autoScalingGroupName/example-asg"
      }
    }
  }

  assert {
    condition     = module.capacity_provider["asg1"].name != null
    error_message = "Expected the EC2 capacity provider entry to be created via composition and its name to resolve."
  }

  assert {
    condition     = output.cluster_arn != null
    error_message = "Expected the plan to still succeed and resolve the cluster ARN with a capacity provider present."
  }
}

run "namespace_and_existing_namespace_arn_are_mutually_exclusive" {
  command = plan

  variables {
    namespace = {
      name = "example-app"
    }
    existing_namespace_arn = "arn:aws:servicediscovery:us-east-1:123456789012:http-namespace/ns-abcd1234"
  }

  expect_failures = [
    terraform_data.validate_namespace_inputs,
  ]
}
