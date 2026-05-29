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

<h3 align="center">WAF Module</h3>
  <p align="center">
    This module creates and manages an AWS WAFv2 Web ACL, optional IP sets, and optional resource association.
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
## Prerequisites

- An AWS provider configured for the target region.
- **CloudFront WAFs** (`scope = "CLOUDFRONT"`) require the AWS provider to be configured for `us-east-1` regardless of where your other resources reside. Pass the provider explicitly or alias it.
- For WAF logging, a Kinesis Data Firehose delivery stream, CloudWatch Logs log group, or S3 bucket must exist before passing its ARN via `logging_configuration.log_destination_configs`.
- IP set ARNs referenced in `rule` statements must already be created (either by this module's `ip_sets` input or externally).

## Usage

### Simple Example
This example creates a regional WAF WebACL with the AWS Managed Common Rule Set and blocks by default.
```
module "waf" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/waf"

  name        = "example-waf"
  scope       = "REGIONAL"
  description = "WAF for example ALB"

  default_action = "block"

  rule = {
    aws_common_rules = {
      name            = "aws-common-rules"
      priority        = 10
      override_action = "none"
      statement = {
        managed_rule_group_statement = {
          name        = "AWSManagedRulesCommonRuleSet"
          vendor_name = "AWS"
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "aws-common-rules"
        sampled_requests_enabled   = true
      }
    }
  }

  associate_with_resource = module.alb.arn

  tags = {
    Environment = "production"
    Terraform   = "true"
  }
}
```

### IP Allowlist Example
This example creates a WAF that only allows traffic from specific IP ranges.
```
module "waf" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/waf"

  name           = "ip-allowlist-waf"
  scope          = "REGIONAL"
  default_action = "block"

  ip_sets = {
    allowlist = {
      name               = "office-ips"
      ip_address_version = "IPV4"
      addresses          = ["203.0.113.0/24", "198.51.100.0/24"]
    }
  }

  rule = {
    allow_office_ips = {
      name     = "allow-office-ips"
      priority = 1
      action   = "allow"
      statement = {
        ip_set_reference_statement = {
          arn = module.waf.ip_sets["allowlist"].arn
        }
      }
      visibility_config = {
        cloudwatch_metrics_enabled = true
        metric_name                = "allow-office-ips"
        sampled_requests_enabled   = true
      }
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Notes / Design Decisions

- **`default_action = "block"`**: The module defaults to blocking all requests not matched by a rule. This is the most secure posture. Override to `"allow"` if your rules are not yet exhaustive and you want to start in monitoring mode.
- **`action` vs. `override_action`**: Use `action` for rules that use IP set, regex, geo, rate, byte, or custom statement types. Use `override_action` for rules that use `managed_rule_group_statement` — AWS WAFv2 requires managed rule groups to use `override_action`, not `action`. Setting both on the same rule will cause a WAFv2 API error.
- **`visibility_config.metric_name`**: If left null, the metric name falls back to the WebACL `name` via `coalesce()`. Rule-level metric names must be specified explicitly in each rule's `visibility_config`.
- **Scope**: REGIONAL WAFs can be attached to ALBs, API Gateways, AppSync APIs, Cognito user pools, and App Runner services. CLOUDFRONT WAFs attach to CloudFront distributions and must be created in `us-east-1`.
- **WAF Logging**: Logging is optional. When provided, the module creates an `aws_wafv2_logging_configuration` resource. You must pre-create the log destination (Firehose, CloudWatch Logs, or S3). Checkov check `CKV2_AWS_31` is suppressed because the log destination is caller-supplied.
- **`rule_action_overrides`**: Currently only supports overriding individual managed rules to `count` mode. Phase 3 of the refactor will expand this to support all action types.
- **Rule management via `aws_wafv2_web_acl_rule`**: Rules are managed as separate `aws_wafv2_web_acl_rule` Terraform resources (not as inline `rule {}` blocks inside the Web ACL). This prevents deletion-ordering errors when IP sets are destroyed while still referenced by a rule, eliminates spurious diffs from AWS returning rules in unpredictable order, and prevents one rule change from recreating all rules. The Web ACL resource has `lifecycle { ignore_changes = [rule] }` as required by the provider.
- **Zero-downtime migration**: If you are upgrading from an older version of this module that used inline rules, Terraform will show new `aws_wafv2_web_acl_rule` resources in the plan. Because `aws_wafv2_web_acl_rule` uses create-or-adopt semantics (if a rule with the same `name` already exists in the Web ACL, it is adopted rather than created), applying the plan makes no infrastructure changes. **Always run `tofu plan` and confirm there are no unexpected replacements before applying.**

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.47.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_wafv2_ip_set.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_ip_set) | resource |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_association) | resource |
| [aws_wafv2_web_acl_logging_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |
| [aws_wafv2_web_acl_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_associate_with_resource"></a> [associate\_with\_resource](#input\_associate\_with\_resource) | The ARN of the resource to associate with the web ACL. Supported resources include ALB, API Gateway REST API, AppSync GraphQL API, or Cognito user pool. | `string` | `null` | no |
| <a name="input_association_config"></a> [association\_config](#input\_association\_config) | Specifies custom configurations for the associations between the web ACL and protected resources. Controls request body inspection size limits per resource type. | <pre>object({<br/>    request_body = optional(object({<br/>      api_gateway = optional(object({<br/>        default_size_inspection_limit = optional(string, "KB_16")<br/>      }))<br/>      app_runner_service = optional(object({<br/>        default_size_inspection_limit = optional(string, "KB_16")<br/>      }))<br/>      cognito_user_pool = optional(object({<br/>        default_size_inspection_limit = optional(string, "KB_16")<br/>      }))<br/>      verified_access_instance = optional(object({<br/>        default_size_inspection_limit = optional(string, "KB_16")<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_captcha_config"></a> [captcha\_config](#input\_captcha\_config) | Specifies how AWS WAF should handle CAPTCHA evaluations at the Web ACL level. | <pre>object({<br/>    immunity_time_property = optional(object({<br/>      immunity_time = optional(number, 300)<br/>    }), { immunity_time = 300 })<br/>  })</pre> | `null` | no |
| <a name="input_challenge_config"></a> [challenge\_config](#input\_challenge\_config) | Specifies how AWS WAF should handle Challenge evaluations at the Web ACL level. | <pre>object({<br/>    immunity_time_property = optional(object({<br/>      immunity_time = optional(number, 300)<br/>    }), { immunity_time = 300 })<br/>  })</pre> | `null` | no |
| <a name="input_custom_response_body"></a> [custom\_response\_body](#input\_custom\_response\_body) | Map of custom response bodies that can be referenced by custom\_response block actions. Key is the unique response body key used in rule actions. | <pre>map(object({<br/>    content      = string<br/>    content_type = string<br/>  }))</pre> | `{}` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | The action to perform if none of the rules contained in the WebACL match. Valid values are 'allow' or 'block'. | `string` | `"block"` | no |
| <a name="input_description"></a> [description](#input\_description) | A friendly description of the WebACL. | `string` | `"WAF WebACL managed by Terraform"` | no |
| <a name="input_ip_sets"></a> [ip\_sets](#input\_ip\_sets) | Map of IP sets to create and manage alongside the WAF WebACL. | <pre>map(object({<br/>    name               = string<br/>    description        = optional(string, "IP set created by WAF module")<br/>    ip_address_version = optional(string, "IPV4")<br/>    addresses          = list(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_logging_configuration"></a> [logging\_configuration](#input\_logging\_configuration) | WAF logging configuration. Set log\_destination\_configs to a list of Kinesis Firehose, CloudWatch Logs, or S3 ARNs. redacted\_fields and logging\_filter are optional. | <pre>object({<br/>    log_destination_configs = list(string)<br/>    redacted_fields = optional(list(object({<br/>      single_header = optional(object({ name = string }))<br/>      uri_path      = optional(object({}))<br/>      query_string  = optional(object({}))<br/>      method        = optional(object({}))<br/>    })), [])<br/>    logging_filter = optional(object({<br/>      default_behavior = string<br/>      filter = list(object({<br/>        behavior    = string<br/>        requirement = string<br/>        condition = list(object({<br/>          action_condition     = optional(object({ action = string }))<br/>          label_name_condition = optional(object({ label_name = string }))<br/>        }))<br/>      }))<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | A friendly name of the WebACL. Must be unique within the AWS region. | `string` | n/a | yes |
| <a name="input_rule"></a> [rule](#input\_rule) | Map of rules to configure on the WAF WebACL. Use 'action' for IP set and regex rules; use 'override\_action' for managed rule group rules. | <pre>map(object({<br/>    name            = string<br/>    priority        = number<br/>    action          = optional(string) # "allow", "block", or "count" — used for non-managed-rule-group statements<br/>    override_action = optional(string) # "none" or "count" — used with managed_rule_group_statement<br/>    statement = object({<br/>      managed_rule_group_statement = optional(object({<br/>        name                  = string<br/>        vendor_name           = string<br/>        rule_action_overrides = optional(list(string), []) # rule names to override to count mode<br/>      }))<br/>      not_statement = optional(object({<br/>        ip_set_reference_statement = object({<br/>          arn = string<br/>        })<br/>      }))<br/>      ip_set_reference_statement = optional(object({<br/>        arn = string<br/>      }))<br/>    })<br/>    captcha_config = optional(object({<br/>      immunity_time_property = optional(object({<br/>        immunity_time = optional(number, 300)<br/>      }), { immunity_time = 300 })<br/>    }), { immunity_time_property = { immunity_time = 300 } })<br/>    challenge_config = optional(object({<br/>      immunity_time_property = optional(object({<br/>        immunity_time = optional(number, 300)<br/>      }), { immunity_time = 300 })<br/>    }), { immunity_time_property = { immunity_time = 300 } })<br/>    visibility_config = object({<br/>      cloudwatch_metrics_enabled = bool<br/>      metric_name                = string<br/>      sampled_requests_enabled   = bool<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | Specifies whether this is for an AWS CloudFront distribution or a regional application. Valid values are CLOUDFRONT or REGIONAL. | `string` | `"REGIONAL"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to assign to all resources. | `map(string)` | `{}` | no |
| <a name="input_token_domains"></a> [token\_domains](#input\_token\_domains) | Specifies the domains to use for CAPTCHA and Challenge token sharing. Required when using CAPTCHA or Challenge across multiple domains. | `list(string)` | `null` | no |
| <a name="input_visibility_config"></a> [visibility\_config](#input\_visibility\_config) | Visibility configuration for the WAF ACL. metric\_name defaults to the WAF name if not specified. | <pre>object({<br/>    cloudwatch_metrics_enabled = optional(bool, true)<br/>    metric_name                = optional(string)<br/>    sampled_requests_enabled   = optional(bool, true)<br/>  })</pre> | <pre>{<br/>  "cloudwatch_metrics_enabled": true,<br/>  "metric_name": null,<br/>  "sampled_requests_enabled": true<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_associated_resource_arn"></a> [associated\_resource\_arn](#output\_associated\_resource\_arn) | The ARN of the associated resource (if any) |
| <a name="output_association_id"></a> [association\_id](#output\_association\_id) | The ID of the WAF association (if created) |
| <a name="output_ip_sets"></a> [ip\_sets](#output\_ip\_sets) | Map of created IP sets |
| <a name="output_logging_configuration_id"></a> [logging\_configuration\_id](#output\_logging\_configuration\_id) | The ARN of the WAF WebACL used as the logging configuration resource ID (if logging is configured) |
| <a name="output_waf_acl_arn"></a> [waf\_acl\_arn](#output\_waf\_acl\_arn) | The ARN of the WAF WebACL |
| <a name="output_waf_acl_id"></a> [waf\_acl\_id](#output\_waf\_acl\_id) | The ID of the WAF WebACL |
| <a name="output_waf_acl_name"></a> [waf\_acl\_name](#output\_waf\_acl\_name) | The name of the WAF WebACL |
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

* [Zachary Hill](https://zacharyhill.co)
* [Jake Jones](https://github.com/jakeasarus)

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