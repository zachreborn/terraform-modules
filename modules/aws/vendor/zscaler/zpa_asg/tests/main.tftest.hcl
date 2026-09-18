mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-west-2"
    }
  }

  mock_data "aws_ami" {
    defaults = {
      id = "ami-0abc123def4567890"
    }
  }

  mock_resource "aws_launch_template" {
    defaults = {
      id             = "lt-0123456789abcdef0"
      arn            = "arn:aws:ec2:us-west-2:123456789012:launch-template/lt-0123456789abcdef0"
      latest_version = 1
      name           = "zpa-test-lt"
    }
  }

  mock_resource "aws_security_group" {
    defaults = {
      id  = "sg-0123456789abcdef0"
      arn = "arn:aws:ec2:us-west-2:123456789012:security-group/sg-0123456789abcdef0"
    }
  }

  mock_resource "aws_autoscaling_group" {
    defaults = {
      id  = "zpa-test"
      arn = "arn:aws:autoscaling:us-west-2:123456789012:autoScalingGroup:uuid:autoScalingGroupName/zpa-test"
    }
  }
}

variables {
  name                 = "zpa-test"
  vpc_id               = "vpc-0123456789abcdef0"
  subnet_ids           = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]
  iam_instance_profile = "ssm-role"
  provisioning_key     = "test-provisioning-key"
  key_name             = "test-key"
  tags = {
    terraform = "true"
  }
}

run "valid_baseline_plans" {
  command = plan

  assert {
    condition     = aws_autoscaling_group.zpa.min_size == 3
    error_message = "Expected default min_size 3."
  }

  assert {
    condition     = aws_autoscaling_group.zpa.desired_capacity == 3
    error_message = "Expected default desired_capacity 3."
  }

  assert {
    condition     = aws_autoscaling_group.zpa.max_size == 4
    error_message = "Expected default max_size 4."
  }

  assert {
    condition     = aws_autoscaling_group.zpa.max_instance_lifetime == 7776000
    error_message = "Expected default max_instance_lifetime 7776000 (90 days)."
  }

  assert {
    condition     = length(aws_autoscaling_group.zpa.termination_policies) == 2
    error_message = "Expected two stacked termination policies."
  }

  assert {
    condition     = aws_autoscaling_group.zpa.termination_policies[0] == "OldestLaunchTemplate"
    error_message = "Expected OldestLaunchTemplate first."
  }

  assert {
    condition     = aws_autoscaling_group.zpa.termination_policies[1] == "OldestInstance"
    error_message = "Expected OldestInstance second."
  }

  assert {
    condition     = aws_launch_template.zpa.image_id == "ami-0abc123def4567890"
    error_message = "Expected mocked Marketplace AMI on launch template."
  }

  assert {
    condition     = length(aws_autoscaling_policy.cpu_target) == 0
    error_message = "CPU target tracking should be off by default."
  }

  assert {
    condition     = output.asg_name == "zpa-test"
    error_message = "asg_name should match var.name."
  }
}

run "cpu_tracking_enabled" {
  command = plan

  variables {
    enable_cpu_target_tracking = true
    cpu_target_value           = 40
  }

  assert {
    condition     = length(aws_autoscaling_policy.cpu_target) == 1
    error_message = "Expected CPU target tracking policy when enabled."
  }
}

run "ami_override" {
  command = plan

  variables {
    ami_id = "ami-11112222333344445"
  }

  assert {
    condition     = aws_launch_template.zpa.image_id == "ami-11112222333344445"
    error_message = "Expected ami_id override on launch template."
  }
}
