NLB
```hcl
module "nlb" {
  source = "./terraform-modules/modules/aws/nlb"

  name               = "my-nlb"
  internal          = false
  load_balancer_type = "network"
  subnets           = ["subnet-1234", "subnet-5678"]

  enable_cross_zone_load_balancing = true

  tags = {
    Environment = "production"
  }
}
```

For an ALB:

```hcl
module "alb" {
  source = "./terraform-modules/modules/aws/nlb"

  name               = "my-alb"
  internal          = false
  load_balancer_type = "application"
  security_groups    = ["sg-1234"]
  subnets           = ["subnet-1234", "subnet-5678"]

  access_logs = {
    bucket  = "my-alb-logs"
    prefix  = "my-alb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

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
| <a name="input_access_logs"></a> [access\_logs](#input\_access\_logs) | Access logs configuration for the LB | <pre>object({<br/>    bucket  = string<br/>    prefix  = string<br/>    enabled = bool<br/>  })</pre> | `null` | no |
| <a name="input_customer_owned_ipv4_pool"></a> [customer\_owned\_ipv4\_pool](#input\_customer\_owned\_ipv4\_pool) | The ID of the customer owned ipv4 pool to use for this load balancer | `string` | `null` | no |
| <a name="input_desync_mitigation_mode"></a> [desync\_mitigation\_mode](#input\_desync\_mitigation\_mode) | Determines how the load balancer handles requests that might pose a security risk to your application | `string` | `"defensive"` | no |
| <a name="input_enable_cross_zone_load_balancing"></a> [enable\_cross\_zone\_load\_balancing](#input\_enable\_cross\_zone\_load\_balancing) | If true, cross-zone load balancing of the load balancer will be enabled | `bool` | `false` | no |
| <a name="input_enable_deletion_protection"></a> [enable\_deletion\_protection](#input\_enable\_deletion\_protection) | If true, deletion of the load balancer will be disabled | `bool` | `false` | no |
| <a name="input_internal"></a> [internal](#input\_internal) | If true, the LB will be internal | `bool` | `false` | no |
| <a name="input_ip_address_type"></a> [ip\_address\_type](#input\_ip\_address\_type) | The type of IP addresses used by the subnets for your load balancer | `string` | `"ipv4"` | no |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Map of listener rule configurations | `any` | `{}` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Map of listener configurations | `any` | `{}` | no |
| <a name="input_load_balancer_type"></a> [load\_balancer\_type](#input\_load\_balancer\_type) | Type of load balancer. Valid values are application or network | `string` | `"network"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the load balancer | `string` | n/a | yes |
| <a name="input_security_groups"></a> [security\_groups](#input\_security\_groups) | List of security group IDs to assign to the LB | `list(string)` | `[]` | no |
| <a name="input_subnet_mappings"></a> [subnet\_mappings](#input\_subnet\_mappings) | List of subnet mapping configurations | `list(map(string))` | `[]` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | List of subnet IDs to attach to the LB | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to the resource | `map(string)` | `{}` | no |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target group configurations | `any` | `{}` | no |

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