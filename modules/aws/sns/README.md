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
<!-- END_TF_DOCS -->
