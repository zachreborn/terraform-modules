# SQS Queue

Manages one `aws_sqs_queue.queue`, with optional customer-managed encryption
composed through `../kms`. The singleton address is intentional: scale with
caller `for_each` while keeping existing state addresses stable.

## Prerequisites and versions

- OpenTofu or Terraform language version **1.3.0+** (optional object attributes,
  permanent moves and resource preconditions).
- `hashicorp/aws` **6.8.0+**: this release added the 1048576-byte message limit.
- An AWS provider configuration, appropriate queue/key permissions, and existing
  keys or producer/consumer permissions when applicable. This module does not
  create roles, Lambda functions, mappings or monitoring.
- Native mock tests require OpenTofu **1.9+**, independently of the language floor.
  Terraform **1.7+** can run the native mock tests.

The examples use repository-local sources. For remote consumption, replace
`source` with
`github.com/zachreborn/terraform-modules//modules/aws/sqs_queue?ref=<released-tag-or-reviewed-commit>`.
Pin the eventual release containing this implementation, not an older tag that
lacks these inputs. Review the consumer plan before adoption.

## Required work-queue configuration

The dead-letter queue in this example must already exist; its identifier is a
fake example. Neither a key nor an alias is created.

```hcl
module "work" {
  source = "./modules/aws/sqs_queue"

  name                       = "webhook-work"
  create_kms_key             = false
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 720
  redrive_policy = jsonencode({
    deadLetterTargetArn = "arn:aws:sqs:us-east-1:123456789012:webhook-dlq"
    maxReceiveCount     = 4
  })
  tags = { Team = "platform" }
}
```

## Multiple queues from a map or YAML

Separate dependency layers avoid cycles between sibling instances of the same
module call. This example creates the 14-day dead-letter queue before connecting
the work queue. Add more entries to either map without duplicating declarations.

```hcl
locals {
  queues = {
    dlq = {
      name        = "webhook-dlq"
      dead_letter = true
      dlq_key     = null
    }
    work = {
      name        = "webhook-work"
      dead_letter = false
      dlq_key     = "dlq"
    }
  }
  # Alternatively: queues = yamldecode(file("${path.module}/queues.yaml"))
}

module "dlqs" {
  source   = "./modules/aws/sqs_queue"
  for_each = { for key, queue in local.queues : key => queue if queue.dead_letter }

  name                      = each.value.name
  create_kms_key            = false
  sqs_managed_sse_enabled   = true
  message_retention_seconds = 1209600
}

module "queues" {
  source   = "./modules/aws/sqs_queue"
  for_each = { for key, queue in local.queues : key => queue if !queue.dead_letter }

  name                       = each.value.name
  create_kms_key             = false
  sqs_managed_sse_enabled    = true
  visibility_timeout_seconds = 720
  redrive_policy = jsonencode({
    deadLetterTargetArn = module.dlqs[each.value.dlq_key].arn
    maxReceiveCount     = 4
  })
}
```

The corresponding `queues.yaml`:

```yaml
dlq:
  name: webhook-dlq
  dead_letter: true
  dlq_key: null
work:
  name: webhook-work
  dead_letter: false
  dlq_key: dlq
```

Configure `redrive_allow_policy` inline on a DLQ when required:
`jsonencode({redrivePermission = "byQueue", sourceQueueArns = ["arn:aws:sqs:us-east-1:123456789012:webhook-work"]})`.
Use known source ARNs, or a separate caller policy-management layer; making the
DLQ depend on the work queue while the work queue depends on the DLQ is a cycle.
`allowAll` and `denyAll` must omit `sourceQueueArns`. Do not separately manage
the same inline policy with a provider policy resource.

## Encryption and design decisions

- Defaults are intentionally unchanged: `create_kms_key = true` creates one key
  and alias. The legacy description remains `"CloudTrail kms key used to encrypt audit logs"`,
  rotation stays enabled, deletion remains 30 days and alias prefix stays
  `alias/sqs_key_`. Override every legacy `key_*` setting explicitly if needed.
- For an existing key, set `create_kms_key = false` and `kms_master_key_id` to
  its ARN, key ID or alias (including `alias/aws/sqs`). Created-key outputs are
  null in this mode; `effective_kms_master_key_id` returns the exact reference.
- For SQS-owned encryption, set `create_kms_key = false` and
  `sqs_managed_sse_enabled = true`. Any non-null SQS encryption selection,
  **including false**, conflicts with created or external KMS encryption.
- With key creation disabled and no external key, a null SQS encryption input
  delegates to the provider/service default. Explicit false permits intentional
  unencrypted operation; no default is silently changed. KMS reuse is omitted
  in both non-KMS modes.
- Generated key policies use declared account/partition/region data and never
  reference the queue resource. Account-root administration delegates permission
  management to the account. Service-use delegation limits actions to
  `kms:Decrypt` and `kms:GenerateDataKey`, the caller account, regional SQS service
  and queue encryption-context ARN. Names use `:<queue-name>`, **not** `:queue/`.
  With `name = null`, the restriction is `:<prefix>*`; fully generated names
  retain only account/region scope. Supply `key_policy` for additional principals
  or custom constraints; explicit policies skip identity/partition/region data.
  Producers and consumers still need appropriate IAM permissions.
- `region` applies to queue, key and alias, including generated policy ARNs.
  A null region delegates to the provider. Name tags are additive and use the
  physical input name, then prefix, then `"sqs"` for fully generated naming.
  Caller tags override them on both queue and created key.
  KMS `ViaService` names intentionally use `.amazonaws.com` in **all**
  partitions, including China, per the
  [KMS condition-key documentation](https://docs.aws.amazon.com/kms/latest/developerguide/conditions-kms.html#conditions-kms-via-service).
  ARN partitions still use the actual partition.
- Numeric inputs enforce integers and full bounds, not substring regexes.
  Convertible numeric strings such as `"720"` remain accepted; invalid strings
  fail type conversion before validation. Message-size default stays 262144,
  but the accepted upper boundary is 1048576.
- FIFO queues require `.fifo` on explicit names. For generated FIFO names the
  provider appends the suffix. High-throughput `perMessageGroupId` requires
  `deduplication_scope = "messageGroup"`. FIFO options on standard queues fail.
- Queue policies require JSON and explicit `Version = "2012-10-17"`.
  Redrive JSON uses a numeric, not string, `maxReceiveCount` from 1 through 1000.
  All three optional operation timeouts are forwarded when supplied.
- No lifecycle ignores conceal encryption, timing, naming or redrive drift.

## Adoption, permanent moves and imports

Preserve physical names, FIFO type, encryption, retention, visibility and delivery
counts. A move relocates an object already in the same state; import is for an
object not in state. Never import an object that is already managed a second time.

For caller modules keyed `work` and `dlq`, these are complete address-only moves:

```hcl
moved {
  from = aws_sqs_queue.work
  to   = module.queues["work"].aws_sqs_queue.queue
}

moved {
  from = aws_sqs_queue.dlq
  to   = module.queues["dlq"].aws_sqs_queue.queue
}
```

For the layered example above, the DLQ destination is instead
`module.dlqs["dlq"].aws_sqs_queue.queue`. Match your actual module keys and keep
them stable; do not include two moves for the same source object.

This module permanently retains the following **actual** declarations internally;
existing module callers do not need to repeat them:

```hcl
moved {
  from = aws_kms_key.sqs
  to   = module.kms[0].aws_kms_key.this
}

moved {
  from = aws_kms_alias.sqs
  to   = module.kms[0].aws_kms_alias.this
}
```

Queues import by URL. For an unmanaged queue only, a declarative import
(OpenTofu/Terraform 1.5+) can be:

```hcl
import {
  to = module.queues["work"].aws_sqs_queue.queue
  id = "https://sqs.us-east-1.amazonaws.com/123456789012/webhook-work"
}
```

Default KMS callers must first adopt the child refactor with key creation still
enabled. Key spec/usage, alias prefix and queue address stay unchanged; repaired
policy and additive Name tags can cause **in-place** changes. Switching encryption
or disposing of an old key is a separate, explicit consumer operation, not an
address-only migration. Already SQS-encrypted native queues adopt with
`create_kms_key = false` and `sqs_managed_sse_enabled = true` from the outset.
Review a real consumer plan and reject unintended replacement/destruction.
Mocked tests do not certify a particular production state.

## Release and validation notes

New encryption/redrive options are additive; corrected validation, previously
undeclared data sources and policy scoping are repairs. The raised language and
provider floors are **breaking toolchain changes** under this repository's strict
versioning policy and require a major release unless maintainers split the work.
No encryption redesign or resource recreation is implied by adoption.

Run from the repository root:

```sh
tofu -chdir=modules/aws/sqs_queue init -backend=false
tofu -chdir=modules/aws/sqs_queue validate
tofu -chdir=modules/aws/sqs_queue test
python3 modules/aws/sqs_queue/tests/check_wiring.py
tofu -chdir=modules/aws/sqs_queue fmt -check -recursive
terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/sqs_queue
```

The supplemental standard-library Python check inspects the two real-child
mocked apply states to verify private KMS resource attributes unavailable through
native module output traversal. It never accesses live state or AWS.
It also proves all seven numeric inputs reject malformed strings as type errors.
Synthetic same-state migration and cross-module adoption checks are separate integration
checks; ordinary fresh native runs alone do not prove state migration.

Schema references:
[queue source v6.8.0](https://github.com/hashicorp/terraform-provider-aws/blob/v6.8.0/internal/service/sqs/queue.go),
[registry documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue).
The immutable schema accepts 1 MiB despite the older versioned prose still
describing 256 KiB.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.8.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.8.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms"></a> [kms](#module\_kms) | ../kms | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_sqs_queue.queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_content_based_deduplication"></a> [content\_based\_deduplication](#input\_content\_based\_deduplication) | Content-based deduplication for FIFO queues. | `bool` | `false` | no |
| <a name="input_create_kms_key"></a> [create\_kms\_key](#input\_create\_kms\_key) | Create the legacy customer-managed key and alias through the KMS child module. | `bool` | `true` | no |
| <a name="input_deduplication_scope"></a> [deduplication\_scope](#input\_deduplication\_scope) | FIFO deduplication scope: queue or messageGroup. | `string` | `null` | no |
| <a name="input_delay_seconds"></a> [delay\_seconds](#input\_delay\_seconds) | Message delivery delay, integer seconds from 0 through 900. | `number` | `0` | no |
| <a name="input_fifo_queue"></a> [fifo\_queue](#input\_fifo\_queue) | Whether to create a FIFO queue; changing queue type replaces the queue. | `bool` | `false` | no |
| <a name="input_fifo_throughput_limit"></a> [fifo\_throughput\_limit](#input\_fifo\_throughput\_limit) | FIFO throughput limit: perQueue or perMessageGroupId. | `string` | `null` | no |
| <a name="input_key_customer_master_key_spec"></a> [key\_customer\_master\_key\_spec](#input\_key\_customer\_master\_key\_spec) | Legacy KMS key specification. SQS-created keys must use SYMMETRIC\_DEFAULT. | `string` | `"SYMMETRIC_DEFAULT"` | no |
| <a name="input_key_deletion_window_in_days"></a> [key\_deletion\_window\_in\_days](#input\_key\_deletion\_window\_in\_days) | Created key deletion waiting period, integer days from 7 through 30. | `number` | `30` | no |
| <a name="input_key_description"></a> [key\_description](#input\_key\_description) | Description passed unchanged to the created key; the historical audit-log description is retained for compatibility. | `string` | `"CloudTrail kms key used to encrypt audit logs"` | no |
| <a name="input_key_enable_key_rotation"></a> [key\_enable\_key\_rotation](#input\_key\_enable\_key\_rotation) | Enable automatic rotation on the created key (legacy default true). | `bool` | `true` | no |
| <a name="input_key_is_enabled"></a> [key\_is\_enabled](#input\_key\_is\_enabled) | Whether the created key is enabled. | `bool` | `true` | no |
| <a name="input_key_name_prefix"></a> [key\_name\_prefix](#input\_key\_name\_prefix) | Created alias prefix, including the required alias/ prefix. | `string` | `"alias/sqs_key_"` | no |
| <a name="input_key_policy"></a> [key\_policy](#input\_key\_policy) | Explicit created-key JSON policy; null generates an account-delegated, queue-scoped service-use policy. | `string` | `null` | no |
| <a name="input_key_usage"></a> [key\_usage](#input\_key\_usage) | Created key usage; SQS requires ENCRYPT\_DECRYPT. | `string` | `"ENCRYPT_DECRYPT"` | no |
| <a name="input_kms_data_key_reuse_period_seconds"></a> [kms\_data\_key\_reuse\_period\_seconds](#input\_kms\_data\_key\_reuse\_period\_seconds) | KMS data-key reuse interval, integer seconds from 60 through 86400; omitted in non-KMS modes. | `number` | `300` | no |
| <a name="input_kms_master_key_id"></a> [kms\_master\_key\_id](#input\_kms\_master\_key\_id) | External KMS key ARN, key ID or alias; requires create\_kms\_key = false. | `string` | `null` | no |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size) | Maximum message size, integer bytes from 1024 through 1048576; null uses the provider default. | `number` | `262144` | no |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds) | Message retention, integer seconds from 60 through 1209600. | `number` | `345600` | no |
| <a name="input_name"></a> [name](#input\_name) | Physical queue name; explicitly set null for provider-generated naming. | `string` | n/a | yes |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Generated queue-name prefix, mutually exclusive with a non-null name. | `string` | `null` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | Queue access-policy JSON with explicit Version = 2012-10-17; managed inline only. | `string` | `null` | no |
| <a name="input_receive_wait_time_seconds"></a> [receive\_wait\_time\_seconds](#input\_receive\_wait\_time\_seconds) | Long-poll wait, integer seconds from 0 through 20; null uses the provider default. | `number` | `0` | no |
| <a name="input_redrive_allow_policy"></a> [redrive\_allow\_policy](#input\_redrive\_allow\_policy) | Inline DLQ permission JSON: allowAll, denyAll, or byQueue with 1 through 10 sourceQueueArns. | `string` | `null` | no |
| <a name="input_redrive_policy"></a> [redrive\_policy](#input\_redrive\_policy) | Inline dead-letter JSON with nonempty deadLetterTargetArn and numeric integer maxReceiveCount from 1 through 1000. | `string` | `null` | no |
| <a name="input_region"></a> [region](#input\_region) | Region override for both queue and created key; null uses the provider region. | `string` | `null` | no |
| <a name="input_sqs_managed_sse_enabled"></a> [sqs\_managed\_sse\_enabled](#input\_sqs\_managed\_sse\_enabled) | SQS-owned encryption selection; omit for KMS. With no KMS, null delegates to the provider and false explicitly disables encryption. | `bool` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Queue and created-key tags; caller values override the additive Name tag. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update and delete operation timeout strings. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | Visibility timeout, integer seconds from 0 through 43200. Numeric strings remain convertible. | `number` | `30` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | Queue ARN. |
| <a name="output_effective_kms_master_key_id"></a> [effective\_kms\_master\_key\_id](#output\_effective\_kms\_master\_key\_id) | Exact KMS reference passed to the queue, including external IDs or aliases. |
| <a name="output_id"></a> [id](#output\_id) | Queue URL (legacy output). |
| <a name="output_kms_key_arn"></a> [kms\_key\_arn](#output\_kms\_key\_arn) | Created child key ARN; null when key creation is disabled. |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | Created child key ID; null when key creation is disabled. |
| <a name="output_name"></a> [name](#output\_name) | Physical queue name. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Queue tags including provider default tags. |
| <a name="output_url"></a> [url](#output\_url) | Queue URL. |
<!-- END_TF_DOCS -->
