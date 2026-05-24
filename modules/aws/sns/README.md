# SNS Topic Module

## Description

Creates and manages an AWS SNS (Simple Notification Service) topic, optional topic access policy, and topic subscriptions. This module exposes all provider-supported attributes for `aws_sns_topic` and `aws_sns_topic_subscription`.

## Prerequisites

- If using a customer-managed KMS key (`kms_master_key_id`), the KMS key must be provisioned beforehand via the `modules/aws/kms` module and the key policy must permit SNS to use it.

## Usage

```hcl
module "notifications" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/sns"

  name              = "my-app-notifications"
  kms_master_key_id = "alias/aws/sns"

  subscriptions = {
    ops_email = {
      protocol = "email"
      endpoint = "ops@example.com"
    }
  }

  tags = {
    Team        = "platform"
    Environment = "prod"
  }
}
```

### With a custom topic policy

```hcl
data "aws_iam_policy_document" "eventbridge_publish" {
  statement {
    sid    = "AllowEventBridgePublish"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
    actions   = ["sns:Publish"]
    resources = ["*"]
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:events:us-east-1:123456789012:rule/my-rule"]
    }
  }
}

module "notifications" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/sns"

  name   = "my-app-notifications"
  policy = data.aws_iam_policy_document.eventbridge_publish.json
}
```

## Notes / Design Decisions

- **Encryption at rest**: `kms_master_key_id` defaults to `alias/aws/sns` (the AWS-managed SNS KMS key) to satisfy CIS AWS Foundations Benchmark 3.9 and Well-Architected security pillar guidance. Set to `null` to disable encryption, or provide a customer-managed key ARN/alias.
- **Topic policy**: When `policy` is `null` (the default), no `aws_sns_topic_policy` resource is created and AWS's default policy applies (account root has full access). Callers that need EventBridge, SQS, or cross-account access should render a policy with `data "aws_iam_policy_document"` and pass it in.
- **FIFO topics**: Setting `fifo_topic = true` automatically appends `.fifo` to the topic name as required by AWS.
- **Subscriptions**: Use the `subscriptions` map to manage any number of subscriptions in a single module call. All `aws_sns_topic_subscription` attributes are exposed as optional object fields.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_sns_topic.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic) | resource |
| [aws_sns_topic_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_policy) | resource |
| [aws_sns_topic_subscription.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sns_topic_subscription) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_failure_feedback_role_arn"></a> [application\_failure\_feedback\_role\_arn](#input\_application\_failure\_feedback\_role\_arn) | IAM role ARN for delivery status failure feedback for application endpoints. | `string` | `null` | no |
| <a name="input_application_success_feedback_role_arn"></a> [application\_success\_feedback\_role\_arn](#input\_application\_success\_feedback\_role\_arn) | IAM role ARN for delivery status success feedback for application endpoints. | `string` | `null` | no |
| <a name="input_application_success_feedback_sample_rate"></a> [application\_success\_feedback\_sample\_rate](#input\_application\_success\_feedback\_sample\_rate) | Percentage of successful deliveries to sample for application endpoint feedback. Valid values are 0-100. | `number` | `null` | no |
| <a name="input_content_based_deduplication"></a> [content\_based\_deduplication](#input\_content\_based\_deduplication) | Enables content-based deduplication for FIFO topics. | `bool` | `false` | no |
| <a name="input_delivery_policy"></a> [delivery\_policy](#input\_delivery\_policy) | JSON string for the SNS topic delivery policy. | `string` | `null` | no |
| <a name="input_display_name"></a> [display\_name](#input\_display\_name) | Display name for the SNS topic. Used as the sender name in email notifications. | `string` | `null` | no |
| <a name="input_fifo_topic"></a> [fifo\_topic](#input\_fifo\_topic) | Whether to create a FIFO (first-in, first-out) topic. When true, the topic name will have '.fifo' appended automatically. | `bool` | `false` | no |
| <a name="input_firehose_failure_feedback_role_arn"></a> [firehose\_failure\_feedback\_role\_arn](#input\_firehose\_failure\_feedback\_role\_arn) | IAM role ARN for delivery status failure feedback for Firehose endpoints. | `string` | `null` | no |
| <a name="input_firehose_success_feedback_role_arn"></a> [firehose\_success\_feedback\_role\_arn](#input\_firehose\_success\_feedback\_role\_arn) | IAM role ARN for delivery status success feedback for Firehose endpoints. | `string` | `null` | no |
| <a name="input_firehose_success_feedback_sample_rate"></a> [firehose\_success\_feedback\_sample\_rate](#input\_firehose\_success\_feedback\_sample\_rate) | Percentage of successful deliveries to sample for Firehose endpoint feedback. Valid values are 0-100. | `number` | `null` | no |
| <a name="input_http_failure_feedback_role_arn"></a> [http\_failure\_feedback\_role\_arn](#input\_http\_failure\_feedback\_role\_arn) | IAM role ARN for delivery status failure feedback for HTTP/HTTPS endpoints. | `string` | `null` | no |
| <a name="input_http_success_feedback_role_arn"></a> [http\_success\_feedback\_role\_arn](#input\_http\_success\_feedback\_role\_arn) | IAM role ARN for delivery status success feedback for HTTP/HTTPS endpoints. | `string` | `null` | no |
| <a name="input_http_success_feedback_sample_rate"></a> [http\_success\_feedback\_sample\_rate](#input\_http\_success\_feedback\_sample\_rate) | Percentage of successful deliveries to sample for HTTP/HTTPS endpoint feedback. Valid values are 0-100. | `number` | `null` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | ID of the AWS KMS key to use for server-side encryption of the SNS topic. Use 'alias/aws/sns' for the AWS-managed key. Defaults to the AWS-managed SNS key for encryption at rest. | `string` | `"alias/aws/sns"` | no |
| <a name="input_lambda_failure_feedback_role_arn"></a> [lambda\_failure\_feedback\_role\_arn](#input\_lambda\_failure\_feedback\_role\_arn) | IAM role ARN for delivery status failure feedback for Lambda endpoints. | `string` | `null` | no |
| <a name="input_lambda_success_feedback_role_arn"></a> [lambda\_success\_feedback\_role\_arn](#input\_lambda\_success\_feedback\_role\_arn) | IAM role ARN for delivery status success feedback for Lambda endpoints. | `string` | `null` | no |
| <a name="input_lambda_success_feedback_sample_rate"></a> [lambda\_success\_feedback\_sample\_rate](#input\_lambda\_success\_feedback\_sample\_rate) | Percentage of successful deliveries to sample for Lambda endpoint feedback. Valid values are 0-100. | `number` | `null` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the SNS topic. Mutually exclusive with name\_prefix. When fifo\_topic is true, '.fifo' is appended automatically. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Name prefix for the SNS topic. Mutually exclusive with name. A unique suffix is appended by AWS. | `string` | `null` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | JSON string for the SNS topic access policy. When null, no topic policy is created and AWS defaults apply. | `string` | `null` | no |
| <a name="input_signature_version"></a> [signature\_version](#input\_signature\_version) | Signature version used for SNS notifications. Valid values are 1 (SHA1) or 2 (SHA256). Defaults to 1. | `number` | `null` | no |
| <a name="input_sqs_failure_feedback_role_arn"></a> [sqs\_failure\_feedback\_role\_arn](#input\_sqs\_failure\_feedback\_role\_arn) | IAM role ARN for delivery status failure feedback for SQS endpoints. | `string` | `null` | no |
| <a name="input_sqs_success_feedback_role_arn"></a> [sqs\_success\_feedback\_role\_arn](#input\_sqs\_success\_feedback\_role\_arn) | IAM role ARN for delivery status success feedback for SQS endpoints. | `string` | `null` | no |
| <a name="input_sqs_success_feedback_sample_rate"></a> [sqs\_success\_feedback\_sample\_rate](#input\_sqs\_success\_feedback\_sample\_rate) | Percentage of successful deliveries to sample for SQS endpoint feedback. Valid values are 0-100. | `number` | `null` | no |
| <a name="input_subscriptions"></a> [subscriptions](#input\_subscriptions) | Map of SNS topic subscriptions to create. The key is a logical name for the subscription. | <pre>map(object({<br/>    confirmation_timeout_in_minutes = optional(number, 1)<br/>    delivery_policy                 = optional(string)<br/>    endpoint                        = string<br/>    endpoint_auto_confirms          = optional(bool, false)<br/>    filter_policy                   = optional(string)<br/>    filter_policy_scope             = optional(string)<br/>    protocol                        = string<br/>    raw_message_delivery            = optional(bool, false)<br/>    redrive_policy                  = optional(string)<br/>    replay_policy                   = optional(string)<br/>    subscription_role_arn           = optional(string)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to all resources. | `map(string)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_tracing_config"></a> [tracing\_config](#input\_tracing\_config) | Tracing mode for the SNS topic. Valid values are PassThrough or Active. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_subscription_arns"></a> [subscription\_arns](#output\_subscription\_arns) | Map of subscription logical names to their ARNs. |
| <a name="output_topic_arn"></a> [topic\_arn](#output\_topic\_arn) | The ARN of the SNS topic. |
| <a name="output_topic_id"></a> [topic\_id](#output\_topic\_id) | The ID of the SNS topic (same as the ARN). |
| <a name="output_topic_name"></a> [topic\_name](#output\_topic\_name) | The name of the SNS topic. |
| <a name="output_topic_owner"></a> [topic\_owner](#output\_topic\_owner) | The AWS account ID of the SNS topic owner. |
<!-- END_TF_DOCS -->
