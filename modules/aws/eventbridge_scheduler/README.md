<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
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
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">EventBridge Scheduler</h3>
  <p align="center">
    Creates and manages an AWS EventBridge Scheduler schedule (aws_scheduler_schedule) — a flexible, timezone-aware, single-target scheduled invocation, with an optional composed least-privilege invoke role.
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
    <li><a href="#prerequisites">Prerequisites</a></li>
    <li><a href="#notes--design-decisions">Notes / Design Decisions</a></li>
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

### Daily Lambda Invocation with a Static Payload and a Module-Created Invoke Role

The module derives a least-privilege `lambda:InvokeFunction` invoke role automatically since `target_role_arn` is omitted.

```hcl
module "paylocity_sync_schedule" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/eventbridge_scheduler"

  name                 = "paylocity-ad-sync-daily"
  schedule_expression  = "cron(0 6 * * ? *)"
  target_arn           = aws_lambda_function.paylocity_sync.arn
  target_input         = jsonencode({ apply = false })

  tags = {
    terraform   = "true"
    environment = "prod"
    team        = "identity"
  }
}
```

### Flexible Time Window with a Non-UTC Timezone

```hcl
module "nightly_report_schedule" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/eventbridge_scheduler"

  name                          = "nightly-report"
  schedule_expression           = "cron(0 23 * * ? *)"
  schedule_expression_timezone  = "America/Denver"
  target_arn                    = aws_lambda_function.nightly_report.arn

  flexible_time_window = {
    mode                      = "FLEXIBLE"
    maximum_window_in_minutes = 15
  }
}
```

### Caller-Supplied Invoke Role

When `target_role_arn` is set, this module does not create an invoke role or policy.

```hcl
module "queue_drainer_schedule" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/eventbridge_scheduler"

  name             = "queue-drainer"
  schedule_expression = "rate(5 minutes)"
  target_arn       = aws_sqs_queue.work.arn
  target_role_arn  = aws_iam_role.existing_scheduler_role.arn
}
```

### ECS Target with Explicit Invoke Policy Actions

ECS targets are not derivable automatically (the schedule's `target_arn` is the *cluster* ARN, but the invoke policy must be scoped to the task definition and paired with `iam:PassRole`), so `target_role_policy_actions` and `target_role_policy_resources` must be supplied explicitly.

```hcl
module "batch_job_schedule" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/eventbridge_scheduler"

  name                          = "nightly-batch-job"
  schedule_expression           = "cron(0 2 * * ? *)"
  target_arn                    = aws_ecs_cluster.batch.arn
  target_role_policy_actions    = ["ecs:RunTask", "iam:PassRole"]
  target_role_policy_resources  = [aws_ecs_task_definition.batch_job.arn]

  target_ecs_parameters = {
    task_definition_arn = aws_ecs_task_definition.batch_job.arn
    launch_type         = "FARGATE"
    network_configuration = {
      subnets          = [aws_subnet.private_a.id, aws_subnet.private_b.id]
      security_groups  = [aws_security_group.batch_job.id]
      assign_public_ip = false
    }
  }
}
```

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Prerequisites

- The target (Lambda function, SQS queue, state machine, ECS cluster, etc.) must already exist; this module only invokes it, it does not create it.
- If `kms_key_arn` is set, the customer-managed KMS key must already exist. This module does not call `modules/aws/kms`.
- If `target_dead_letter_arn` is set, the destination SQS queue must already exist. This module does not call `modules/aws/sqs_queue`, but it does extend the generated invoke policy with `sqs:SendMessage` on that queue.
- If `group_name` is set, the schedule group must already exist. This module only consumes a group by name; it does not create `aws_scheduler_schedule_group` resources.

## Notes / Design Decisions

- **`aws_scheduler_schedule` accepts no `tags` argument.** EventBridge Scheduler supports tags on schedule *groups*, not on individual schedules, so `var.tags` reaches only the composed invoke role and policy this module creates — never the schedule resource itself.
- **Least-privilege invoke action derivation.** When `target_role_arn` is omitted, the generated invoke policy is scoped to `target_arn` (never `"*"`) using an action derived from the ARN's service namespace (e.g. `lambda:InvokeFunction`, `sqs:SendMessage`). ECS and universal targets (`arn:<partition>:scheduler:::aws-sdk:<service>:<action>`) cannot be derived this way and fail the plan with a clear message directing the caller to set `target_role_policy_actions` (and usually `target_role_policy_resources`) explicitly.
- **`aws:SourceArn` is omitted under `name_prefix`.** The generated trust policy always pins `aws:SourceAccount`. It additionally pins `aws:SourceArn` to the schedule's constructed ARN, but only when `name` is set — under `name_prefix` the final name isn't known until apply, so that condition is left out and only `aws:SourceAccount` applies.
- **Provider floor is `>= 6.14.0`, above the repo's `>= 6.0.0` baseline.** `action_after_completion` was added to `aws_scheduler_schedule` in `hashicorp/aws` v6.14.0 ([PR #44264](https://github.com/hashicorp/terraform-provider-aws/pull/44264)); every other argument this module sets exists at the repo baseline. Callers pinned to `hashicorp/aws` 6.0–6.13 cannot use this module.
- **Single schedule per module call.** This module manages one schedule, matching its closest sibling `modules/aws/cloudwatch/event`. Callers needing many schedules should use `for_each` on the module block rather than a map/YAML fan-out input, since each schedule's optional composed invoke role and policy would otherwise require its own nested fan-out.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.14.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.14.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_target_invoke_policy"></a> [target\_invoke\_policy](#module\_target\_invoke\_policy) | ../iam/policy | n/a |
| <a name="module_target_role"></a> [target\_role](#module\_target\_role) | ../iam/role | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_scheduler_schedule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/scheduler_schedule) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_action_after_completion"></a> [action\_after\_completion](#input\_action\_after\_completion) | (Optional) Action applied to the schedule after completing invocation of its target. | `string` | `null` | no |
| <a name="input_description"></a> [description](#input\_description) | (Optional) Brief description of the schedule. | `string` | `null` | no |
| <a name="input_end_date"></a> [end\_date](#input\_end\_date) | (Optional) UTC RFC3339 instant before which the schedule can invoke its target, e.g. 2030-01-01T01:00:00Z. Ignored for one-time schedules. Must be strictly later than start\_date when both are set. | `string` | `null` | no |
| <a name="input_flexible_time_window"></a> [flexible\_time\_window](#input\_flexible\_time\_window) | (Optional) Configures the time window during which EventBridge Scheduler may invoke the schedule. | <pre>object({<br/>    mode                      = optional(string, "OFF")<br/>    maximum_window_in_minutes = optional(number)<br/>  })</pre> | <pre>{<br/>  "mode": "OFF"<br/>}</pre> | no |
| <a name="input_group_name"></a> [group\_name](#input\_group\_name) | (Optional) Name of the schedule group to associate this schedule with. AWS uses the 'default' group when omitted. Forces replacement. | `string` | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | (Optional) ARN of the customer managed KMS key EventBridge Scheduler uses to encrypt and decrypt the schedule's data. The caller must provision this key; this module does not call modules/aws/kms. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) Name of the schedule. Forces replacement. Mutually exclusive with name\_prefix; exactly one of name or name\_prefix must be set. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | (Optional) Creates a unique schedule name beginning with this prefix. Forces replacement. Mutually exclusive with name; exactly one of name or name\_prefix must be set. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Region where the schedule is managed. Defaults to the Region set in the provider configuration. | `string` | `null` | no |
| <a name="input_schedule_expression"></a> [schedule\_expression](#input\_schedule\_expression) | (Required) Defines when the schedule runs: at(...), rate(...), or cron(...). See https://docs.aws.amazon.com/scheduler/latest/UserGuide/schedule-types.html. | `string` | n/a | yes |
| <a name="input_schedule_expression_timezone"></a> [schedule\_expression\_timezone](#input\_schedule\_expression\_timezone) | (Optional) IANA timezone in which schedule\_expression is evaluated. | `string` | `"UTC"` | no |
| <a name="input_start_date"></a> [start\_date](#input\_start\_date) | (Optional) UTC RFC3339 instant after which the schedule may begin invoking its target, e.g. 2030-01-01T01:00:00Z. Ignored for one-time schedules. | `string` | `null` | no |
| <a name="input_state"></a> [state](#input\_state) | (Optional) Whether the schedule is enabled or disabled. | `string` | `"ENABLED"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags applied to the composed IAM role and policy. aws\_scheduler\_schedule has no tags argument (EventBridge Scheduler supports tags only on schedule groups, not individual schedules), so these tags never reach the schedule resource itself. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_target_arn"></a> [target\_arn](#input\_target\_arn) | (Required) ARN of the target to invoke, or a universal-target service ARN (arn:<partition>:scheduler:::aws-sdk:<service>:<action>). | `string` | n/a | yes |
| <a name="input_target_dead_letter_arn"></a> [target\_dead\_letter\_arn](#input\_target\_dead\_letter\_arn) | (Optional) ARN of the SQS queue EventBridge Scheduler uses as a dead-letter queue for failed target invocations. The caller must provision this queue; this module does not call modules/aws/sqs\_queue. | `string` | `null` | no |
| <a name="input_target_ecs_parameters"></a> [target\_ecs\_parameters](#input\_target\_ecs\_parameters) | (Optional) Templated target parameters for the Amazon ECS RunTask API operation. Set target\_role\_policy\_actions and target\_role\_policy\_resources explicitly when this is used, since the ecs:RunTask invoke action cannot be derived automatically. | <pre>object({<br/>    task_definition_arn = string<br/>    capacity_provider_strategy = optional(list(object({<br/>      capacity_provider = string<br/>      base              = optional(number)<br/>      weight            = optional(number)<br/>    })), [])<br/>    enable_ecs_managed_tags = optional(bool)<br/>    enable_execute_command  = optional(bool)<br/>    group                   = optional(string)<br/>    launch_type             = optional(string)<br/>    network_configuration = optional(object({<br/>      assign_public_ip = optional(bool)<br/>      security_groups  = optional(set(string))<br/>      subnets          = optional(set(string))<br/>    }))<br/>    placement_constraints = optional(list(object({<br/>      type       = string<br/>      expression = optional(string)<br/>    })), [])<br/>    placement_strategy = optional(list(object({<br/>      type  = string<br/>      field = optional(string)<br/>    })), [])<br/>    platform_version = optional(string)<br/>    propagate_tags   = optional(string)<br/>    reference_id     = optional(string)<br/>    tags             = optional(map(string))<br/>    task_count       = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_target_eventbridge_parameters"></a> [target\_eventbridge\_parameters](#input\_target\_eventbridge\_parameters) | (Optional) Templated target parameters for the EventBridge PutEvents API operation. | <pre>object({<br/>    detail_type = string<br/>    source      = string<br/>  })</pre> | `null` | no |
| <a name="input_target_input"></a> [target\_input](#input\_target\_input) | (Optional) Text, or well-formed JSON, passed to the target on every invocation, e.g. jsonencode({ apply = false }). | `string` | `null` | no |
| <a name="input_target_kinesis_parameters"></a> [target\_kinesis\_parameters](#input\_target\_kinesis\_parameters) | (Optional) Templated target parameters for the Amazon Kinesis PutRecord API operation. | <pre>object({<br/>    partition_key = string<br/>  })</pre> | `null` | no |
| <a name="input_target_retry_policy"></a> [target\_retry\_policy](#input\_target\_retry\_policy) | (Optional) Retry policy settings for the target. | <pre>object({<br/>    maximum_event_age_in_seconds = optional(number)<br/>    maximum_retry_attempts       = optional(number)<br/>  })</pre> | `null` | no |
| <a name="input_target_role_additional_policy_arns"></a> [target\_role\_additional\_policy\_arns](#input\_target\_role\_additional\_policy\_arns) | (Optional) Additional managed or customer-managed policy ARNs to attach to the created invoke role alongside the generated least-privilege policy (e.g. kms:GenerateDataKey for an encrypted SQS target). | `list(string)` | `[]` | no |
| <a name="input_target_role_arn"></a> [target\_role\_arn](#input\_target\_role\_arn) | (Optional) ARN of an existing IAM role for EventBridge Scheduler to assume when invoking the target. When omitted, this module creates a least-privilege invoke role via modules/aws/iam/role and modules/aws/iam/policy. | `string` | `null` | no |
| <a name="input_target_role_max_session_duration"></a> [target\_role\_max\_session\_duration](#input\_target\_role\_max\_session\_duration) | (Optional) Maximum session duration, in seconds, for the created invoke role. | `number` | `3600` | no |
| <a name="input_target_role_name"></a> [target\_role\_name](#input\_target\_role\_name) | (Optional) Name of the invoke role and policy this module creates when target\_role\_arn is omitted. When null, a name\_prefix derived from the schedule name is used instead. | `string` | `null` | no |
| <a name="input_target_role_path"></a> [target\_role\_path](#input\_target\_role\_path) | (Optional) Path for the created invoke role and policy. | `string` | `"/"` | no |
| <a name="input_target_role_permissions_boundary"></a> [target\_role\_permissions\_boundary](#input\_target\_role\_permissions\_boundary) | (Optional) ARN of the permissions boundary policy for the created invoke role. | `string` | `null` | no |
| <a name="input_target_role_policy_actions"></a> [target\_role\_policy\_actions](#input\_target\_role\_policy\_actions) | (Optional) IAM actions the created invoke policy allows. Overrides the action this module would otherwise derive from target\_arn's service namespace. Required when the target service cannot be derived (e.g. ECS, universal targets). | `list(string)` | `null` | no |
| <a name="input_target_role_policy_resources"></a> [target\_role\_policy\_resources](#input\_target\_role\_policy\_resources) | (Optional) Resources the created invoke policy allows target\_role\_policy\_actions against. Defaults to [target\_arn] when unset. | `list(string)` | `null` | no |
| <a name="input_target_sagemaker_pipeline_parameters"></a> [target\_sagemaker\_pipeline\_parameters](#input\_target\_sagemaker\_pipeline\_parameters) | (Optional) Templated target parameters for the Amazon SageMaker AI StartPipelineExecution API operation. | <pre>object({<br/>    pipeline_parameter = optional(list(object({<br/>      name  = string<br/>      value = string<br/>    })), [])<br/>  })</pre> | `null` | no |
| <a name="input_target_sqs_parameters"></a> [target\_sqs\_parameters](#input\_target\_sqs\_parameters) | (Optional) Templated target parameters for the Amazon SQS SendMessage API operation. | <pre>object({<br/>    message_group_id = optional(string)<br/>  })</pre> | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN of the schedule. |
| <a name="output_group_name"></a> [group\_name](#output\_group\_name) | Schedule group the schedule belongs to. |
| <a name="output_id"></a> [id](#output\_id) | ID of the schedule (its name). |
| <a name="output_name"></a> [name](#output\_name) | Resolved name of the schedule, including one generated from name\_prefix. |
| <a name="output_schedule_expression"></a> [schedule\_expression](#output\_schedule\_expression) | The applied schedule expression. |
| <a name="output_schedule_expression_timezone"></a> [schedule\_expression\_timezone](#output\_schedule\_expression\_timezone) | The applied schedule expression timezone. |
| <a name="output_state"></a> [state](#output\_state) | Whether the schedule is enabled or disabled, as applied. |
| <a name="output_target_arn"></a> [target\_arn](#output\_target\_arn) | ARN of the invoked target, read from the schedule's target block. |
| <a name="output_target_assume_role_policy_json"></a> [target\_assume\_role\_policy\_json](#output\_target\_assume\_role\_policy\_json) | Generated trust policy document for the created invoke role; null when no role was created. |
| <a name="output_target_invoke_policy_arn"></a> [target\_invoke\_policy\_arn](#output\_target\_invoke\_policy\_arn) | ARN of the generated invoke policy; null when the caller supplied target\_role\_arn. |
| <a name="output_target_invoke_policy_json"></a> [target\_invoke\_policy\_json](#output\_target\_invoke\_policy\_json) | Generated least-privilege invoke policy document; null when no role was created. |
| <a name="output_target_role_arn"></a> [target\_role\_arn](#output\_target\_role\_arn) | Resolved invoke role ARN, whether supplied via target\_role\_arn or created by this module. |
| <a name="output_target_role_created"></a> [target\_role\_created](#output\_target\_role\_created) | True when this module created the invoke role. |
| <a name="output_target_role_name"></a> [target\_role\_name](#output\_target\_role\_name) | Name of the invoke role created by this module; null when the caller supplied target\_role\_arn. |
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
- [Jake Jones](https://github.com/jakeasaurus)

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
