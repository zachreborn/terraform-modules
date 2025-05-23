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

### Application Load Balancer with Target Group and Listener

This example creates an Application Load Balancer (ALB) in AWS with associated target groups, listeners, and listener rules. The ALB is configured as internal-facing within the specified VPC private subnets and uses a security group for access control. The target group is configured to use instance targets with HTTP protocol on port 80, including health checks. An HTTP listener is created on port 80 that forwards traffic to the target group. The module also includes listener rules for source IP-based routing, allowing traffic from specific CIDR ranges (192.168.1.0/24 and 10.0.0.0/8). The configuration supports sticky sessions using load balancer cookies and allows for customization of health check parameters, security settings, and tags.

```
module "example_alb" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lb?ref=LATEST-VERSION-HERE"
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
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.load_balancer](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |
| [aws_lb_listener.listener](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.listener_rule](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |
| [aws_lb_target_group.target_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | Access logs configuration for the LB | <pre>map(object({<br/>    bucket  = string<br/>    prefix  = string<br/>    enabled = bool<br/>  }))</pre> | `null` | no |
| <a name="input_client_keep_alive"></a> [client\_keep\_alive](#input\_client\_keep\_alive) | (Optional) Client keep alive value in seconds. The valid range is 60-604800 seconds. The default is 3600 seconds. | `number` | `3600` | no |
| <a name="input_connection_logs"></a> [connection\_logs](#input\_connection\_logs) | (Optional) Connection Logs block. See below. Only valid for Load Balancers of type application. | <pre>map(object({<br/>    bucket  = string<br/>    prefix  = string<br/>    enabled = bool<br/>  }))</pre> | `null` | no |
| <a name="input_customer_owned_ipv4_pool"></a> [customer\_owned\_ipv4\_pool](#input\_customer\_owned\_ipv4\_pool) | The ID of the customer owned ipv4 pool to use for this load balancer | `string` | `null` | no |
| <a name="input_desync_mitigation_mode"></a> [desync\_mitigation\_mode](#input\_desync\_mitigation\_mode) | Determines how the load balancer handles requests that might pose a security risk to your application | `string` | `"defensive"` | no |
| <a name="input_dns_record_client_routing_policy"></a> [dns\_record\_client\_routing\_policy](#input\_dns\_record\_client\_routing\_policy) | (Optional) How traffic is distributed among the load balancer Availability Zones. Possible values are any\_availability\_zone (default), availability\_zone\_affinity, or partial\_availability\_zone\_affinity. See Availability Zone DNS affinity for additional details. Only valid for network type load balancers. | `string` | `"any_availability_zone"` | no |
| <a name="input_drop_invalid_header_fields"></a> [drop\_invalid\_header\_fields](#input\_drop\_invalid\_header\_fields) | Indicates whether invalid header fields are dropped in application load balancers | `bool` | `false` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | If true, cross-zone load balancing of the load balancer will be enabled | `bool` | `false` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | If true, deletion of the load balancer will be disabled | `bool` | `false` | no |
| <a name="input_enable_http2"></a> [enable\_http2](#input\_enable\_http2) | Indicates whether HTTP/2 is enabled in application load balancers | `bool` | `true` | no |
| <a name="input_enable_tls_version_and_cipher_suite_headers"></a> [enable\_tls\_version\_and\_cipher\_suite\_headers](#input\_enable\_tls\_version\_and\_cipher\_suite\_headers) | (Optional) Whether the two headers (x-amzn-tls-version and x-amzn-tls-cipher-suite), which contain information about the negotiated TLS version and cipher suite, are added to the client request before sending it to the target. Only valid for Load Balancers of type application. Defaults to false | `bool` | `false` | no |
| <a name="input_enable_waf_fail_open"></a> [enable\_waf\_fail\_open](#input\_enable\_waf\_fail\_open) | Indicates whether to allow a WAF-enabled load balancer to route requests to targets if it is unable to forward the request to AWS WAF | `bool` | `false` | no |
| <a name="input_enable_xff_client_port"></a> [enable\_xff\_client\_port](#input\_enable\_xff\_client\_port) | (Optional) Whether the X-Forwarded-For header should preserve the source port that the client used to connect to the load balancer in application load balancers. Defaults to false. | `bool` | `false` | no |
| <a name="input_enable_zonal_shift"></a> [enable\_zonal\_shift](#input\_enable\_zonal\_shift) | (Optional) Whether zonal shift is enabled. Defaults to false. | `bool` | `false` | no |
| <a name="input_enforce_security_group_inbound_rules_on_private_link_traffic"></a> [enforce\_security\_group\_inbound\_rules\_on\_private\_link\_traffic](#input\_enforce\_security\_group\_inbound\_rules\_on\_private\_link\_traffic) | (Optional) Whether inbound security group rules are enforced for traffic originating from a PrivateLink. Only valid for Load Balancers of type network. The possible values are on and off. | `string` | `null` | no |
| <a name="input_idle_timeout"></a> [idle\_timeout](#input\_idle\_timeout) | The time in seconds that the connection is allowed to be idle | `number` | `60` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | If true, the LB will be internal | `bool` | `false` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | The type of IP addresses used by the subnets for your load balancer | `string` | `"ipv4"` | no |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Map of listener rule configurations | <pre>map(object({<br/>    listener_key = string<br/>    priority     = optional(number)<br/><br/>    action = object({<br/>      type             = string<br/>      target_group_arn = optional(string)<br/><br/>      fixed_response = optional(object({<br/>        content_type = string<br/>        message_body = optional(string)<br/>        status_code  = optional(string)<br/>      }))<br/><br/>      redirect = optional(object({<br/>        path        = optional(string)<br/>        host        = optional(string)<br/>        port        = optional(string)<br/>        protocol    = optional(string)<br/>        query       = optional(string)<br/>        status_code = string<br/>      }))<br/>    })<br/><br/>    conditions = list(object({<br/>      host_header = optional(object({<br/>        values = list(string)<br/>      }))<br/><br/>      http_header = optional(map(object({<br/>        http_header_name = string<br/>        values           = list(string)<br/>      })))<br/><br/>      path_pattern = optional(object({<br/>        values = list(string)<br/>      }))<br/><br/>      query_string = optional(map(object({<br/>        key   = optional(string)<br/>        value = string<br/>      })))<br/><br/>      source_ip = optional(object({<br/>        values = list(string)<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Map of listener configurations | <pre>map(object({<br/>    port            = number<br/>    protocol        = string<br/>    ssl_policy      = optional(string)<br/>    certificate_arn = optional(string)<br/>    alpn_policy     = optional(string)<br/><br/>    authenticate_oidc = optional(object({<br/>      authorization_endpoint = string<br/>      client_id              = string<br/>      client_secret          = string<br/>      issuer                 = string<br/>      token_endpoint         = string<br/>      user_info_endpoint     = string<br/>    }))<br/><br/>    authenticate_cognito = optional(object({<br/>      user_pool_arn       = string<br/>      user_pool_client_id = string<br/>      user_pool_domain    = string<br/>    }))<br/><br/>    mutual_authentication = optional(object({<br/>      mode = string # Only valid field, can be "verify" or "strict"<br/>    }))<br/><br/>    default_action = object({<br/>      type             = string<br/>      target_group_arn = optional(string)<br/><br/>      fixed_response = optional(object({<br/>        content_type = string<br/>        message_body = optional(string)<br/>        status_code  = optional(string)<br/>      }))<br/><br/>      redirect = optional(object({<br/>        path        = optional(string)<br/>        host        = optional(string)<br/>        port        = optional(string)<br/>        protocol    = optional(string)<br/>        query       = optional(string)<br/>        status_code = string<br/>      }))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | Type of load balancer. Valid values are application, gateway, or network | `string` | `"network"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the load balancer | `string` | n/a | yes |
| <a name="input_preserve_host_header"></a> [preserve\_host\_header](#input\_preserve\_host\_header) | Optional) Whether the Application Load Balancer should preserve the Host header in the HTTP request and send it to the target without any change. Defaults to false. | `bool` | `false` | no |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of security group IDs to assign to the LB | `list(string)` | `[]` | no |
| <a name="input_subnet_mappings"></a> [subnet\_mappings](#input\_subnet\_mappings) | A list of subnet mapping configurations with optional values. | <pre>map(object({<br/>    subnet_id            = string<br/>    allocation_id        = optional(string, null)<br/>    private_ipv4_address = optional(string, null)<br/>    ipv6_address         = optional(string, null)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target group configurations | <pre>map(object({<br/>    name                               = string<br/>    port                               = number<br/>    protocol                           = string<br/>    target_type                        = string<br/>    vpc_id                             = string<br/>    deregistration_delay               = optional(number)<br/>    slow_start                         = optional(number)<br/>    load_balancing_algorithm_type      = optional(string)<br/>    target_group_proxy_protocol_v2     = optional(bool)<br/>    target_group_preserve_client_ip    = optional(bool)<br/>    protocol_version                   = optional(string)<br/>    connection_termination             = optional(bool)<br/>    lambda_multi_value_headers_enabled = optional(bool)<br/>    health_check = map(object({<br/>      enabled              = optional(bool, true)<br/>      healthy_threshold    = optional(number, 3)<br/>      interval             = optional(number, 30)<br/>      matcher              = optional(string)<br/>      path                 = optional(string)<br/>      port                 = optional(string, "traffic-port")<br/>      protocol             = optional(string, "HTTP")<br/>      timeout              = optional(number, 5)<br/>      unhealthy_threshold  = optional(number, 3)<br/>      success_codes        = optional(string)<br/>      grace_period_seconds = optional(number)<br/>    }))<br/><br/>    stickiness = set(object({<br/>      type            = string<br/>      cookie_duration = optional(number)<br/>      cookie_name     = optional(string)<br/>    }))<br/><br/>    tags = optional(map(string), {})<br/>  }))</pre> | `{}` | no |
| <a name="input_xff_header_processing_mode"></a> [xff\_header\_processing\_mode](#input\_xff\_header\_processing\_mode) | (Optional) Determines how the load balancer modifies the X-Forwarded-For header in the HTTP request before sending the request to the target. The possible values are append, preserve, and remove. Only valid for Load Balancers of type application. The default is append. | `string` | `"append"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the load balancer |
| <a name="output_arn_suffix"></a> [arn\_suffix](#output\_arn\_suffix) | The ARN suffix for use with CloudWatch Metrics |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name of the load balancer |
| <a name="output_id"></a> [id](#output\_id) | The ID of the load balancer |
| <a name="output_listener_rules"></a> [listener\_rules](#output\_listener\_rules) | Map of listener rules created and their attributes |
| <a name="output_listeners"></a> [listeners](#output\_listeners) | Map of listeners created and their attributes |
| <a name="output_name"></a> [name](#output\_name) | The name of the load balancer |
| <a name="output_target_groups"></a> [target\_groups](#output\_target\_groups) | Map of target groups created and their attributes |
| <a name="output_vpc_id"></a> [vpc\_id](#output\_vpc\_id) | The VPC ID of the load balancer |
| <a name="output_zone_id"></a> [zone\_id](#output\_zone\_id) | The canonical hosted zone ID of the load balancer |
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

[contributors-shield]: https://img.shields.io/github/contributors/zachreborn/terraform-modules.svg?style=for-the-badge
[contributors-url]: https://github.com/zachreborn/terraform-modules/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/zachreborn/terraform-modules.svg?style=for-the-badge
[forks-url]: https://github.com/zachreborn/terraform-modules/network/members
[stars-shield]: https://img.shields.io/github/stars/zachreborn/terraform-modules.svg?style=for-the-badge
[stars-url]: https://github.com/zachreborn/terraform-modules/stargazers
[issues-shield]: https://img.shields.io/github/issues/zachreborn/terraform-modules.svg?style=for-the-badge
[issues-url]: https://github.com/zachreborn/terraform-modules/issues
[license-shield]: https://img.shields.io/github/license/zachreborn/terraform-modules.svg?style=for-the-badge
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
