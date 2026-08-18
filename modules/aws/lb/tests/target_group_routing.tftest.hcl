# Regression coverage for the target_group_key fix: aws_lb_listener.default_action
# and aws_lb_listener_rule.action used to hardcode aws_lb_target_group.target_group
# ["main"], so any listener/rule meant to forward to a non-"main" target group
# either silently routed to the wrong target group, or -- as exercised below, where
# the map has no "main" key at all -- failed outright with an invalid-index error.
# target_group_key (optional, default "main") fixes this. All cases run fully
# offline via mock_provider/mock_resource:
#   tofu init -backend=false && tofu test

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
      arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/mock-tg/0123456789abcdef"
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

# Omitting target_group_key entirely must preserve the pre-fix behavior of
# routing to the "main" target group.
run "default_action_without_target_group_key_routes_to_main" {
  command = plan

  variables {
    name               = "example-alb"
    load_balancer_type = "application"

    target_groups = {
      main = {
        name         = "main-tg"
        port         = 80
        protocol     = "HTTP"
        target_type  = "instance"
        vpc_id       = "vpc-0123456789abcdef0"
        health_check = {}
        stickiness   = []
      }
    }

    listeners = {
      http = {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "forward"
        }
      }
    }
  }

  assert {
    condition     = aws_lb_listener.listener["http"].default_action[0].target_group_arn == aws_lb_target_group.target_group["main"].arn
    error_message = "default_action without an explicit target_group_key should default to routing to the \"main\" target group."
  }
}

# The direct regression test for the bug: target_groups intentionally has no
# "main" key at all, only "secondary". Before this fix, default_action always
# referenced target_group["main"], so this plan would fail with an invalid-index
# error. With target_group_key wired through, it must plan successfully and
# route to "secondary".
run "default_action_with_explicit_target_group_key_routes_to_secondary" {
  command = plan

  variables {
    name               = "example-alb"
    load_balancer_type = "application"

    target_groups = {
      secondary = {
        name         = "secondary-tg"
        port         = 8080
        protocol     = "HTTP"
        target_type  = "instance"
        vpc_id       = "vpc-0123456789abcdef0"
        health_check = {}
        stickiness   = []
      }
    }

    listeners = {
      http = {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type             = "forward"
          target_group_key = "secondary"
        }
      }
    }
  }

  assert {
    condition     = aws_lb_listener.listener["http"].default_action[0].target_group_arn == aws_lb_target_group.target_group["secondary"].arn
    error_message = "default_action with target_group_key=\"secondary\" should route to the secondary target group's ARN."
  }

  assert {
    condition     = one(aws_lb_listener.listener["http"].default_action[0].forward[0].target_group).arn == aws_lb_target_group.target_group["secondary"].arn
    error_message = "The default_action's forward.target_group block should also route to the secondary target group's ARN."
  }
}

# Same regression test for listener_rules[*].action, which had the identical bug.
# Again, target_groups has no "main" key, so this only plans successfully if
# target_group_key is honored.
run "listener_rule_action_with_explicit_target_group_key_routes_to_secondary" {
  command = plan

  variables {
    name               = "example-alb"
    load_balancer_type = "application"

    target_groups = {
      secondary = {
        name         = "secondary-tg"
        port         = 8080
        protocol     = "HTTP"
        target_type  = "instance"
        vpc_id       = "vpc-0123456789abcdef0"
        health_check = {}
        stickiness   = []
      }
    }

    listeners = {
      http = {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type             = "forward"
          target_group_key = "secondary"
        }
      }
    }

    listener_rules = {
      route_to_secondary = {
        listener_key = "http"
        priority     = 10
        action = {
          type             = "forward"
          target_group_key = "secondary"
        }
        # Note: uses source_ip rather than path_pattern/host_header here, since
        # those two condition types have a separate, pre-existing dynamic-block
        # wiring bug unrelated to this PR's target_group_key fix (their for_each
        # iterates the raw single-object value instead of wrapping it in a map,
        # the way source_ip/http_header/query_string correctly do).
        conditions = [{
          source_ip = {
            values = ["10.0.0.0/24"]
          }
        }]
      }
    }
  }

  assert {
    condition     = aws_lb_listener_rule.listener_rule["route_to_secondary"].action[0].target_group_arn == aws_lb_target_group.target_group["secondary"].arn
    error_message = "listener_rules[*].action with target_group_key=\"secondary\" should route to the secondary target group's ARN."
  }
}

# A non-forward listener_rule action (fixed-response) must leave target_group_arn
# null rather than pointing at any target group.
run "listener_rule_non_forward_action_leaves_target_group_arn_null" {
  command = plan

  variables {
    name               = "example-alb"
    load_balancer_type = "application"

    target_groups = {
      main = {
        name         = "main-tg"
        port         = 80
        protocol     = "HTTP"
        target_type  = "instance"
        vpc_id       = "vpc-0123456789abcdef0"
        health_check = {}
        stickiness   = []
      }
    }

    listeners = {
      http = {
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "forward"
        }
      }
    }

    listener_rules = {
      health_check_rule = {
        listener_key = "http"
        priority     = 20
        action = {
          type = "redirect"
        }
        conditions = [{
          source_ip = {
            values = ["203.0.113.0/24"]
          }
        }]
      }
    }
  }

  assert {
    condition     = aws_lb_listener_rule.listener_rule["health_check_rule"].action[0].target_group_arn == null
    error_message = "A non-forward listener_rule action should not have a target_group_arn set."
  }
}

# Do NOT weaken these assertions (or any you add) to force a pass. If a `run` block
# fails, treat it as a signal that the module code has a bug and fix the root cause
# in main.tf / variables.tf / outputs.tf, then re-run `tofu test` until it passes for
# the right reason.
