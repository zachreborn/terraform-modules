mock_provider "aws" {}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    name                   = "example-asg-cp"
    auto_scaling_group_arn = "arn:aws:autoscaling:us-east-1:123456789012:autoScalingGroup:abcd1234:autoScalingGroupName/example-asg"
  }

  assert {
    condition     = aws_ecs_capacity_provider.this.name == "example-asg-cp"
    error_message = "Expected the capacity provider name to match the input name."
  }

  assert {
    condition     = aws_ecs_capacity_provider.this.auto_scaling_group_provider[0].managed_draining == "ENABLED"
    error_message = "Expected managed_draining to default to ENABLED."
  }

  assert {
    condition     = aws_ecs_capacity_provider.this.auto_scaling_group_provider[0].managed_termination_protection == "ENABLED"
    error_message = "Expected managed_termination_protection to default to ENABLED."
  }

  assert {
    condition     = output.id != null
    error_message = "Expected the capacity provider id output to resolve."
  }

  assert {
    condition     = output.arn != null
    error_message = "Expected the capacity provider arn output to resolve."
  }
}
