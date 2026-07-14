mock_provider "aws" {
  mock_data "aws_region" {
    defaults = {
      region = "us-east-1"
    }
  }

  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  mock_resource "aws_instance" {
    defaults = {
      id                           = "i-0123456789abcdef0"
      public_dns                   = "ec2-mock-public.compute-1.amazonaws.com"
      public_ip                    = "mock-public-ip-value"
      primary_network_interface_id = "eni-0123456789abcdef0"
      private_dns                  = "ip-mock-private.ec2.internal"
      security_groups              = []
    }
  }
}

run "plan_succeeds_with_valid_input" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
  }

  assert {
    condition     = length(aws_instance.ec2) == 1
    error_message = "number should default to 1 instance."
  }

  assert {
    condition     = aws_instance.ec2[0].associate_public_ip_address == false
    error_message = "associate_public_ip_address should default to false."
  }

  assert {
    condition     = aws_instance.ec2[0].disable_api_termination == false
    error_message = "disable_api_termination should default to false."
  }

  assert {
    condition     = aws_instance.ec2[0].ebs_optimized == false
    error_message = "ebs_optimized should default to false."
  }

  assert {
    condition     = aws_instance.ec2[0].instance_initiated_shutdown_behavior == "stop"
    error_message = "instance_initiated_shutdown_behavior should default to stop."
  }

  assert {
    condition     = aws_instance.ec2[0].monitoring == false
    error_message = "monitoring should default to false."
  }

  assert {
    condition     = aws_instance.ec2[0].source_dest_check == true
    error_message = "source_dest_check should default to true."
  }

  assert {
    condition     = aws_instance.ec2[0].tenancy == "default"
    error_message = "tenancy should default to default."
  }

  assert {
    condition     = aws_instance.ec2[0].metadata_options[0].http_endpoint == "enabled"
    error_message = "http_endpoint should default to enabled."
  }

  assert {
    condition     = aws_instance.ec2[0].metadata_options[0].http_tokens == "required"
    error_message = "http_tokens should default to required."
  }

  assert {
    condition     = aws_instance.ec2[0].maintenance_options[0].auto_recovery == "default"
    error_message = "auto_recovery should default to default and flow through to maintenance_options."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].delete_on_termination == true
    error_message = "root_delete_on_termination should default to true."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].encrypted == true
    error_message = "encrypted should default to true."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].volume_type == "gp3"
    error_message = "root_volume_type should default to gp3."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].volume_size == 100
    error_message = "root_volume_size should default to 100."
  }

  assert {
    condition     = aws_instance.ec2[0].tags["Name"] == "example"
    error_message = "Name tag should equal var.name with no numeric suffix when number == 1."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].tags["Name"] == "example"
    error_message = "root_block_device Name tag should equal var.name with no numeric suffix when number == 1."
  }

  # Note: iam_instance_profile is Optional+Computed in the aws_instance schema, so a null
  # config value is planned as unknown and OpenTofu's mock provider fills it with a
  # generated placeholder rather than preserving null. Asserting `== null` here would fail
  # even though the module correctly leaves the variable unset -- the override case below
  # ("overrides_are_honored") is what actually proves the module wires this value through.

  assert {
    condition     = length(aws_instance.ec2[0].ipv6_addresses) == 0
    error_message = "ipv6_addresses should default to an empty list."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.instance) == 1
    error_message = "One instance status check alarm should be planned per instance."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.instance[0].alarm_name == "i-0123456789abcdef0-instance-alarm"
    error_message = "instance alarm_name should be derived from the instance id."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.system) == 1
    error_message = "One system status check alarm should be planned per instance."
  }

  assert {
    condition     = aws_cloudwatch_metric_alarm.system[0].alarm_name == "i-0123456789abcdef0-system-alarm"
    error_message = "system alarm_name should be derived from the instance id."
  }

  assert {
    condition     = contains(aws_cloudwatch_metric_alarm.system[0].alarm_actions, "arn:aws:automate:us-east-1:ec2:recover")
    error_message = "system alarm_actions should reference the current region's EC2 auto-recovery automation ARN."
  }

  assert {
    condition     = output.id[0] == "i-0123456789abcdef0"
    error_message = "id output should expose the mocked instance id."
  }

  assert {
    condition     = output.public_ip[0] == "mock-public-ip-value"
    error_message = "public_ip output should expose the mocked public ip."
  }

  # Note: private_ip is Optional+Computed and is explicitly overridden in a later run in
  # this file, so it intentionally has no fixed mock default (OpenTofu rejects a mock
  # default for a field that a run elsewhere sets explicitly via config). Comparing directly
  # against the resource attribute (rather than a fixed literal) keeps this deterministic
  # regardless of what value the mock provider generates.
  assert {
    condition     = output.private_ip[0] == aws_instance.ec2[0].private_ip
    error_message = "private_ip output should expose the instance's private_ip attribute."
  }

  assert {
    condition     = output.public_dns[0] == "ec2-mock-public.compute-1.amazonaws.com"
    error_message = "public_dns output should expose the mocked public dns."
  }

  assert {
    condition     = output.private_dns[0] == "ip-mock-private.ec2.internal"
    error_message = "private_dns output should expose the mocked private dns."
  }

  assert {
    condition     = output.primary_network_interface_id[0] == "eni-0123456789abcdef0"
    error_message = "primary_network_interface_id output should expose the mocked ENI id."
  }

  assert {
    condition     = output.availability_zone[0] == ""
    error_message = "availability_zone output should pass through the (default, empty) input value."
  }

  assert {
    condition     = output.key_name[0] == ""
    error_message = "key_name output should pass through the (default, empty) input value."
  }

  assert {
    condition     = output.subnet_id[0] == ""
    error_message = "subnet_id output should pass through the (default, empty) input value."
  }

  assert {
    condition     = contains(output.vpc_security_group_ids[0], "sg-0123456789abcdef0")
    error_message = "vpc_security_group_ids output should pass through the input value."
  }

  assert {
    condition     = length(output.security_groups[0]) == 0
    error_message = "security_groups output should expose the (mocked, empty) EC2-Classic security_groups attribute."
  }
}

run "overrides_are_honored" {
  command = plan

  variables {
    ami                                  = "ami-0123456789abcdef0"
    instance_type                        = "t3.micro"
    name                                 = "example"
    vpc_security_group_ids               = ["sg-0123456789abcdef0"]
    associate_public_ip_address          = true
    availability_zone                    = "us-east-1a"
    disable_api_termination              = true
    ebs_optimized                        = true
    encrypted                            = false
    iam_instance_profile                 = "example-instance-profile"
    instance_initiated_shutdown_behavior = "terminate"
    ipv6_addresses                       = [format("%s:%s::%s", "2001", "db8", "1")]
    key_name                             = "example-key"
    monitoring                           = true
    placement_group                      = "example-placement-group"
    private_ip                           = format("%s.%s.%s.%s", "192", "0", "2", "10")
    http_endpoint                        = "disabled"
    http_tokens                          = "optional"
    root_delete_on_termination           = false
    root_volume_size                     = "250"
    root_volume_type                     = "io2"
    source_dest_check                    = false
    subnet_id                            = "subnet-0123456789abcdef0"
    tenancy                              = "dedicated"
    user_data                            = "echo 'hello, this is example user data!'"
    tags = {
      team = "platform"
    }
  }

  assert {
    condition     = aws_instance.ec2[0].associate_public_ip_address == true
    error_message = "associate_public_ip_address override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].availability_zone == "us-east-1a"
    error_message = "availability_zone override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].disable_api_termination == true
    error_message = "disable_api_termination override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].ebs_optimized == true
    error_message = "ebs_optimized override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].encrypted == false
    error_message = "encrypted override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].iam_instance_profile == "example-instance-profile"
    error_message = "iam_instance_profile override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].instance_initiated_shutdown_behavior == "terminate"
    error_message = "instance_initiated_shutdown_behavior override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].key_name == "example-key"
    error_message = "key_name override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].monitoring == true
    error_message = "monitoring override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].placement_group == "example-placement-group"
    error_message = "placement_group override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].private_ip == format("%s.%s.%s.%s", "192", "0", "2", "10")
    error_message = "private_ip override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].metadata_options[0].http_endpoint == "disabled"
    error_message = "http_endpoint override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].metadata_options[0].http_tokens == "optional"
    error_message = "http_tokens override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].delete_on_termination == false
    error_message = "root_delete_on_termination override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].volume_size == 250
    error_message = "root_volume_size override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].root_block_device[0].volume_type == "io2"
    error_message = "root_volume_type override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].source_dest_check == false
    error_message = "source_dest_check override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].subnet_id == "subnet-0123456789abcdef0"
    error_message = "subnet_id override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].tenancy == "dedicated"
    error_message = "tenancy override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].user_data == "echo 'hello, this is example user data!'"
    error_message = "user_data override should be honored."
  }

  assert {
    condition     = aws_instance.ec2[0].tags["team"] == "platform"
    error_message = "Custom tags should be merged into the instance tags."
  }
}

run "auto_recovery_override_is_honored" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    auto_recovery          = "disabled"
  }

  # Core regression guard for https://github.com/zachreborn/terraform-modules/issues/397:
  # proves var.auto_recovery is actually wired into the planned maintenance_options block
  # rather than being validated and silently discarded.
  assert {
    condition     = aws_instance.ec2[0].maintenance_options[0].auto_recovery == "disabled"
    error_message = "auto_recovery override should be honored and flow through to maintenance_options."
  }
}

run "number_zero_creates_no_instances_or_alarms" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    number                 = 0
  }

  assert {
    condition     = length(aws_instance.ec2) == 0
    error_message = "number = 0 should create no instances."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.instance) == 0
    error_message = "number = 0 should create no instance status check alarms."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.system) == 0
    error_message = "number = 0 should create no system status check alarms."
  }

  assert {
    condition     = length(output.id) == 0
    error_message = "id output should be an empty list when number = 0."
  }
}

run "number_greater_than_one_suffixes_names_with_index" {
  command = plan

  variables {
    ami                    = "ami-0123456789abcdef0"
    instance_type          = "t3.micro"
    name                   = "example"
    vpc_security_group_ids = ["sg-0123456789abcdef0"]
    number                 = 2
  }

  assert {
    condition     = length(aws_instance.ec2) == 2
    error_message = "number = 2 should create two instances."
  }

  assert {
    condition     = aws_instance.ec2[0].tags["Name"] == "example1"
    error_message = "The first instance's Name tag should be suffixed with 1 when number > 1."
  }

  assert {
    condition     = aws_instance.ec2[1].tags["Name"] == "example2"
    error_message = "The second instance's Name tag should be suffixed with 2 when number > 1."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.instance) == 2
    error_message = "One instance status check alarm should be planned per instance when number > 1."
  }

  assert {
    condition     = length(aws_cloudwatch_metric_alarm.system) == 2
    error_message = "One system status check alarm should be planned per instance when number > 1."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block fails,
# treat it as a signal that the module code has a bug and fix the root cause in main.tf /
# variables.tf / outputs.tf, then re-run `tofu test` until it passes for the right reason.
