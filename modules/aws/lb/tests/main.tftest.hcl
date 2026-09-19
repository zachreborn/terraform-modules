# Native OpenTofu tests for the lb module. All cases run fully offline via
# mock_provider/mock_resource -- no real credentials or backend are required:
#   tofu init -backend=false && tofu test
#
# See AGENTS.md > Module Design Specifications > Native Test Coverage for the full
# requirement. Target-group/listener routing regression coverage lives in
# target_group_routing.tftest.hcl alongside this baseline file.

mock_provider "aws" {
  mock_resource "aws_lb" {
    defaults = {
      id  = "lb-mock"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/example-alb/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      id  = "tg-mock"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/main-tg/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_listener" {
    defaults = {
      id  = "listener-mock"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/example-alb/0123456789abcdef/aaaaaaaaaaaaaaaa"
    }
  }

  mock_resource "aws_lb_listener_rule" {
    defaults = {
      id  = "listener-rule-mock"
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener-rule/app/example-alb/0123456789abcdef/aaaaaaaaaaaaaaaa/bbbbbbbbbbbbbbbb"
    }
  }
}

# aws_lb requires either `subnets` or `subnet_mapping` to be set; this module only
# wires subnet_mappings through, so every run below must supply it. Declared once
# at file scope since every run in this file needs the same value.
variables {
  subnet_mappings = {
    a = {
      subnet_id = "subnet-0123456789abcdef0"
    }
  }
}

# Valid baseline: a network load balancer with a single target group and a
# forward listener, matching the module's own NLB usage example in README.md.
run "plan_succeeds_with_baseline_nlb" {
  command = plan

  variables {
    name               = "example-nlb"
    load_balancer_type = "network"
    internal           = true

    target_groups = {
      main = {
        name         = "main-tg"
        port         = 80
        protocol     = "TCP"
        target_type  = "ip"
        vpc_id       = "vpc-0123456789abcdef0"
        health_check = {}
        stickiness   = []
      }
    }

    listeners = {
      tcp = {
        port     = 80
        protocol = "TCP"
        default_action = {
          type = "forward"
        }
      }
    }
  }

  assert {
    condition     = aws_lb.load_balancer.load_balancer_type == "network"
    error_message = "load_balancer_type should be network for this baseline."
  }

  assert {
    condition     = length(aws_lb_target_group.target_group) == 1
    error_message = "Expected exactly one target group to be created."
  }

  assert {
    condition     = length(aws_lb_listener.listener) == 1
    error_message = "Expected exactly one listener to be created."
  }

  assert {
    condition     = length(aws_lb_listener_rule.listener_rule) == 0
    error_message = "No listener_rules were configured, so none should be created."
  }

  assert {
    condition     = output.arn == aws_lb.load_balancer.arn
    error_message = "arn output should equal the load balancer resource's arn."
  }

  assert {
    condition     = output.name == aws_lb.load_balancer.name
    error_message = "name output should equal the load balancer resource's name."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block
# fails, treat it as a signal that the module code has a bug and fix the root cause
# in main.tf / variables.tf / outputs.tf, then re-run `tofu test` until it passes for
# the right reason.
