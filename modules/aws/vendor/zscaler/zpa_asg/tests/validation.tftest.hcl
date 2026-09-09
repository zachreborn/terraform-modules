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
  subnet_ids           = ["subnet-aaa"]
  iam_instance_profile = "ssm-role"
  provisioning_key     = "test-key"
}

run "rejects_invalid_ami_id" {
  command = plan

  variables {
    ami_id = "not-an-ami"
  }

  expect_failures = [var.ami_id]
}

run "rejects_empty_subnet_ids" {
  command = plan

  variables {
    subnet_ids = []
  }

  expect_failures = [var.subnet_ids]
}

run "rejects_invalid_max_instance_lifetime" {
  command = plan

  variables {
    max_instance_lifetime = 100
  }

  expect_failures = [var.max_instance_lifetime]
}

run "rejects_invalid_root_volume_type" {
  command = plan

  variables {
    root_volume_type = "magnetic"
  }

  expect_failures = [var.root_volume_type]
}

run "rejects_invalid_http_tokens" {
  command = plan

  variables {
    http_tokens = "sometimes"
  }

  expect_failures = [var.http_tokens]
}

run "rejects_invalid_termination_policies" {
  command = plan

  variables {
    termination_policies = ["OldestLaunchTemplat"]
  }

  expect_failures = [var.termination_policies]
}

