# Protected CloudFormation Stack

Creates one `aws_cloudformation_stack` with literal `prevent_destroy = true` and configurable provider operation timeouts. This is a separate entrypoint; the existing `cloudformation/stack` module and its resource addresses are unchanged.

## Prerequisites

- An AWS provider configured for the target account and region.
- An existing template supplied as either a body or a URL.
- An operational SNS topic if event notifications are required. Its policy, encryption permissions, subscribers, and subscription confirmations must be configured before stack creation.
- Deployment permissions for CloudFormation and the resources inside the template, or an existing CloudFormation service role.

## Usage

Pin the source to the tagged library release containing this entrypoint before using it in production.

```hcl
module "archival_stack" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/cloudformation/protected_stack"

  name               = "archival-integration"
  capabilities       = ["CAPABILITY_IAM"]
  template_body      = file("${path.module}/templates/archival.json")
  notification_arns  = [module.operations_topic.arn]
  timeout_in_minutes = 60

  timeouts = {
    create = "90m"
    update = "90m"
    delete = "90m"
  }

  tags = {
    environment = "prod"
    terraform   = "true"
  }
}
```

## Lifecycle and operational notes

- `prevent_destroy` blocks destroy plans and replacements, including stack-name changes. It does not block in-place template updates or destructive changes to resources inside a template. Use a stack update policy where required.
- The guard is not a variable: Terraform/OpenTofu requires a literal lifecycle value. Removing the module configuration also removes the guard. This is not AWS termination protection and does not stop deletion through the AWS console or API.
- Enable AWS termination protection separately where required. This provider resource does not expose that API.
- `prevent_destroy` does not control AWS creation-failure rollback. The default `on_failure = "ROLLBACK"` preserves normal AWS rollback behavior.
- `timeout_in_minutes` is an AWS creation setting; changing it requires replacement with the current provider and is therefore blocked for an existing protected stack. Provider `timeouts` configure how long the client waits for create, update, and delete operations.
- When `disable_rollback = true`, the conflicting `on_failure` argument is omitted. Otherwise, `disable_rollback` is omitted.
- Provide exactly one template input and at most one stack policy input. Body and URL inputs are not silently discarded.
- A CloudFormation custom-resource SNS service token is not an operational event notification destination.
- A newly created stack needs no state migration. Moving an existing stack from another resource/module requires an explicit, reviewed state move or import; do not create a duplicate.

## Tests

```sh
tofu init -backend=false
tofu validate
tofu test
python3 tests/test_lifecycle.py
```

The native tests use a mocked provider and plan-only runs. A mocked apply of a protected resource cannot be automatically torn down by the native test runner; disabling lifecycle protection to make cleanup succeed would defeat the behavior under test.

The Python standard-library harness copies the module into a temporary directory, seeds synthetic state, and runs plans with refresh disabled. It tests all outputs, a no-op baseline, allowed template updates, and rejected destroy/replacement plans. It uses generated dummy credentials, empty credential files, and localhost-only service endpoints; no live plan or apply is performed. It reuses providers installed by `tofu init`. Set `TOFU_BINARY` if `tofu` is not on `PATH`. Both suites run in the module's CI matrix job.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_cloudformation_stack.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_capabilities"></a> [capabilities](#input\_capabilities) | IAM and macro capabilities acknowledged for the template. | `list(string)` | `null` | no |
| <a name="input_disable_rollback"></a> [disable\_rollback](#input\_disable\_rollback) | Disable rollback on creation failure. When true, on\_failure is omitted. | `bool` | `false` | no |
| <a name="input_iam_role_arn"></a> [iam\_role\_arn](#input\_iam\_role\_arn) | Existing CloudFormation service role ARN; null uses the existing stack role or deployment credentials. | `string` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Stable stack name. Changing it requires replacement and is blocked by prevent\_destroy. | `string` | n/a | yes |
| <a name="input_notification_arns"></a> [notification\_arns](#input\_notification\_arns) | Regional operational SNS topic ARNs for stack events, not custom-resource service tokens. | `list(string)` | `null` | no |
| <a name="input_on_failure"></a> [on\_failure](#input\_on\_failure) | Creation failure behavior, omitted when disable\_rollback is true. Null uses the AWS default. | `string` | `"ROLLBACK"` | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | Template parameter names and values. | `map(string)` | `null` | no |
| <a name="input_policy_body"></a> [policy\_body](#input\_policy\_body) | JSON stack update policy; mutually exclusive with policy\_url. | `string` | `null` | no |
| <a name="input_policy_url"></a> [policy\_url](#input\_policy\_url) | Stack update policy URL; mutually exclusive with policy\_body. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Resource region override; null uses the AWS provider region. | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Stack tags. The Name tag is always set to the stack name. | `map(string)` | `{}` | no |
| <a name="input_template_body"></a> [template\_body](#input\_template\_body) | JSON or YAML CloudFormation template body; provide exactly one of template\_body and template\_url. | `string` | `null` | no |
| <a name="input_template_url"></a> [template\_url](#input\_template\_url) | CloudFormation template URL; provide exactly one of template\_body and template\_url. | `string` | `null` | no |
| <a name="input_timeout_in_minutes"></a> [timeout\_in\_minutes](#input\_timeout\_in\_minutes) | AWS creation timeout in whole minutes; distinct from provider operation timeouts. | `number` | `60` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Provider operation timeouts. Null attributes use the provider's 30-minute defaults. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_id"></a> [id](#output\_id) | Stack ARN. |
| <a name="output_name"></a> [name](#output\_name) | Stack name. |
| <a name="output_outputs"></a> [outputs](#output\_outputs) | Outputs exported by the CloudFormation template. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | All stack tags, including provider default tags. |
<!-- END_TF_DOCS -->
