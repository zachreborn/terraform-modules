<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->
<a name="readme-top"></a>


<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]


<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="300" height="300">
  </a>

<h3 align="center">Load Balancer</h3>
  <p align="center">
    This module creates AWS Network and Application Load Balancers.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>


<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>


<!-- USAGE EXAMPLES -->
## Usage
### Network Load Balancer with Target Group and Listener
This example creates a Network Load Balancer (NLB) in AWS with associated target groups and listeners. The NLB is configured as internal-facing within the specified VPC private subnets. The target group is configured to use IP targets with TCP protocol on port 52110, with custom health check settings. A TCP listener is created on port 80 that forwards traffic to the target group. The module allows for configuration of cross-zone load balancing, deletion protection, and custom tags.
```
module "example_nlb" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lb?ref=LATEST-VERSION-HERE"

  # Load Balancer Configuration
  name                             = "example-nlb"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = module.vpc.private_subnet_ids
  enable_cross_zone_load_balancing = false
  enable_deletion_protection       = false

  # Target Group Configuration
  target_groups = {
    main = {
      name        = "example-tg1"
      port        = 52110
      protocol    = "TCP"
      vpc_id      = module.vpc.vpc_id
      target_type = "ip"
      stickiness = [{
        type = "source_ip"
      }]
      health_check = {
        main = {
          enabled             = true
          healthy_threshold   = 3
          interval            = 30
          port                = "traffic-port"
          protocol            = "TCP"
          timeout             = 10
          unhealthy_threshold = 3
        }
      }
    }
  }

  # Listener Configuration
  listeners = {
    tcp = {
      port     = 80
      protocol = "TCP"
      default_action = {
        type = "forward"
      }
    }
  }

  tags = {
    Environment = "some env"
    Terraform   = "true"
    Project     = "just a test"
  }
}
```

### Network Load Balancer with Target Group and Listener
This example creates an Application Load Balancer (ALB) in AWS with associated target groups, listeners, and listener rules. The ALB is configured as internal-facing within the specified VPC private subnets and uses a security group for access control. The target group is configured to use instance targets with HTTP protocol on port 80, including health checks. An HTTP listener is created on port 80 that forwards traffic to the target group. The module also includes listener rules for source IP-based routing, allowing traffic from specific CIDR ranges (192.168.1.0/24 and 10.0.0.0/8). The configuration supports sticky sessions using load balancer cookies and allows for customization of health check parameters, security settings, and tags.
```
module "example_alb" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lb?ref=dev_lb_maps"

  # Load Balancer Configuration
  name                       = "example-alb"
  internal                   = true
  load_balancer_type         = "application"
  subnets                    = module.vpc.private_subnet_ids
  security_groups            = [aws_security_group.lb_sg.id]
  enable_deletion_protection = false

  # Target Group Configuration
  target_groups = {
    main = {
      name        = "example-tg1"
      port        = 80
      protocol    = "HTTP"
      vpc_id      = module.vpc.vpc_id
      target_type = "instance"
      stickiness = [{
        type = "lb_cookie" # Required for ALB
      }]
      health_check = {
        main = {
          enabled             = true
          healthy_threshold   = 3
          interval            = 30
          path                = "/"
          port                = "traffic-port"
          protocol            = "HTTP"
          timeout             = 5
          unhealthy_threshold = 3
        }
      }
    }
  }

  # Listener Configuration
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "forward"
      }
    }
  }

  # Listener Rule Configuration
  listener_rules = {
    ip_based = {
      listener_key = "http"
      priority     = 100
      action = {
        type = "forward"
      }
      conditions = [{
        source_ip = {
          values = ["192.168.1.0/24", "10.0.0.0/8"]
        }
      }]
    }
  }

  tags = {
    Environment = "some env"
    Terraform   = "true"
    Project     = "just a test"
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
