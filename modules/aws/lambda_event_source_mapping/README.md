# Lambda event source mapping

Manages one `aws_lambda_event_source_mapping.this`, connecting an existing Lambda
function to SQS, Kinesis, DynamoDB Streams, Kafka, Amazon MQ or DocumentDB.
The singleton resource address is intentionally unchanged; scale with caller
module `for_each`, not a second resource or an internal map.

## Prerequisites

- An existing function and event source, with execution-role permissions, source
  authentication, networking and destinations provisioned by their owning modules.
- For SQS, configure queue visibility and redrive policy separately. The function
  must implement partial batch responses before enabling `ReportBatchItemFailures`.
  For FIFO processing, stop after the first failure and report unprocessed records.
- Existing customer-managed keys and necessary decrypt permissions when encrypting
  filter criteria; this module never creates keys, roles, queues or functions.
- Terraform >=1.3.0 or OpenTofu >=1.6.0 and `hashicorp/aws` >=6.54.0.
  Optional object defaults set the language floor; configurable operation
  timeouts and propagation-timeout selection set the provider floor.
  Native mocked tests require OpenTofu >=1.9 (or Terraform >=1.7).

## Usage

The required work-queue adoption configuration preserves batch size 10, a
five-second window and exactly the partial-response setting:

```hcl
module "mapping" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lambda_event_source_mapping?ref=<released-tag-or-commit>"

  function_name                      = "arn:aws:lambda:us-east-1:123456789012:function:worker"
  event_source_arn                   = "arn:aws:sqs:us-east-1:123456789012:work"
  batch_size                        = "10"
  enabled                           = "true"
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
}
```

### Multiple mappings from a map or YAML

Keep keys stable: each leaf retains `aws_lambda_event_source_mapping.this`.
An empty map creates no instances.

```hcl
locals {
  mappings = {
    work = {
      function_name    = "worker"
      event_source_arn = "arn:aws:sqs:us-east-1:123456789012:work"
    }
    notifications = {
      function_name    = "notifier"
      event_source_arn = "arn:aws:sqs:us-east-1:123456789012:notifications"
    }
  }
  # Alternatively: mappings = yamldecode(file("${path.module}/mappings.yaml"))
}

module "mappings" {
  source   = "github.com/zachreborn/terraform-modules//modules/aws/lambda_event_source_mapping?ref=<released-tag-or-commit>"
  for_each = local.mappings

  function_name                      = each.value.function_name
  event_source_arn                   = each.value.event_source_arn
  maximum_batching_window_in_seconds = 5
  function_response_types            = ["ReportBatchItemFailures"]
}
```

```yaml
work:
  function_name: worker
  event_source_arn: arn:aws:sqs:us-east-1:123456789012:work
notifications:
  function_name: notifier
  event_source_arn: arn:aws:sqs:us-east-1:123456789012:notifications
```

### Stream example

```hcl
module "stream_mapping" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/lambda_event_source_mapping?ref=<released-tag-or-commit>"

  function_name                        = "stream-worker"
  event_source_arn                     = "arn:aws:kinesis:us-east-1:123456789012:stream/events"
  starting_position                    = "AT_TIMESTAMP"
  starting_position_timestamp          = "2026-01-01T00:00:00Z"
  batch_size                           = "100"
  maximum_batching_window_in_seconds   = 5
  maximum_retry_attempts               = 3
  maximum_record_age_in_seconds        = 3600
  bisect_batch_on_function_error       = true
  function_response_types              = ["ReportBatchItemFailures"]
}
```

## Notes and compatibility

- Legacy `batch_size` and `enabled` remain string inputs with defaults `"10"`
  and `"true"`, explicitly normalized to number/bool. Convertible numeric and
  boolean callers still work. The module's effective batch default remains 10
  for every source, rather than switching existing stream callers to 100.
- `maximum_batching_window_in_seconds=null` preserves the service/provider
  default. Kafka, MQ and DocumentDB default to 500ms. Any integer window loses
  that original default; returning to 500ms requires a new mapping.
  Provider create uses `GetOk` and can omit explicit zero; updates send zero.
  Mocked plan assertions establish argument wiring, not live window transitions.
- Standard SQS batches above 10 require a window >=1; FIFO permits at most 10
  records and no positive window. The current AWS API also documents a window
  >=1 for Kinesis/DynamoDB batches above 10, while historic provider behavior
  accepts stream defaults without that window. This module preserves those
  existing stream configurations; review service requirements before deployment.
- Empty legacy position strings are omitted. Nonempty `starting_position` and
  `starting_position_timestamp` were previously ignored; they are now applied.
  Both are replacement-sensitive fields. SQS never receives either argument.
  Kinesis/DynamoDB require a position; DynamoDB does not support AT_TIMESTAMP.
  Kafka and DocumentDB also support timestamp positions according to the
  current AWS API, notwithstanding older registry wording.
- Kafka supports partial responses, failure destinations, retries and record
  age under current AWS documentation. Do not infer feature availability solely
  from stale registry prose. Provisioned pollers support Kafka and SQS;
  SQS pollers have a minimum of two and cannot combine with maximum-concurrency
  scaling. Kafka minimum pollers may be one. No arbitrary concurrency ceiling
  is imposed.
- Null optional blocks are omitted. Empty `scaling_config={}` remains supported
  to clear concurrency. Up to ten filters are accepted by the provider; six
  through ten require an account quota increase. No quota is changed here.
- Tags add `Name=function_name`, with caller tags winning. This is an additive
  tag diff for existing callers; `tags_all` includes provider defaults.
- There are no lifecycle ignores. Outputs expose the provider's UUID, ARN,
  state and processing metadata; these are not delivery guarantees.

### Release and adoption

The higher tool/provider floors are breaking for older toolchains and require
a major release under this repository's release policy. Added controls/outputs
are additive; malformed-input/source checks and previously ignored stream
arguments are behavior repairs. Encryption, source permissions and operational
changes remain explicit caller decisions. Pin a released tag or immutable
commit rather than an unreviewed branch.

For a native mapping already in the same state, remove the old resource
declaration, configure the module with the exact existing function/source,
batch/window, enabled and response values, then declare:

```hcl
moved {
  from = aws_lambda_event_source_mapping.work
  to   = module.mapping.aws_lambda_event_source_mapping.this
}
```

For the keyed caller variant, use this destination instead (choose only one):

```hcl
moved {
  from = aws_lambda_event_source_mapping.work
  to   = module.mappings["work"].aws_lambda_event_source_mapping.this
}
```

If the mapping is not already managed in the same state, import by mapping
UUID instead of moving or importing an already-managed object a second time:

```hcl
import {
  to = module.mapping.aws_lambda_event_source_mapping.this
  id = "00000000-0000-0000-0000-000000000537"
}
```

Declarative import requires Terraform >=1.5 or OpenTofu. A keyed import uses
`module.mappings["work"].aws_lambda_event_source_mapping.this` with the same
UUID. The public leaf identity remains `aws_lambda_event_source_mapping.this`;
no internal move is necessary for existing module callers. Changes to event
source, source-access settings, topics/queues, Kafka group/registry, or starting
position can require replacement under the provider schema. Review a real
consumer plan and require no unintended destroy/replacement; offline mocks
cannot certify a production state migration. Do not conceal drift with ignores
or recreate infrastructure to perform address-only adoption.

## Verification and authoritative references

Run `tofu init -backend=false`, `tofu validate` and `tofu test` from this
directory. Tests are offline with deterministic computed fixtures and no AWS
credentials or backend. Plan runs cover configurable behavior; mocked apply
asserts exact metadata outputs. Synthetic migration and cross-module adoption
are integrated separately; these module tests do not claim live delivery or
production-state migration verification.

- [Immutable provider schema at 6.54.0](https://github.com/hashicorp/terraform-provider-aws/blob/v6.54.0/internal/service/lambda/event_source_mapping.go)
- [Provider registry documentation](https://registry.terraform.io/providers/hashicorp/aws/6.54.0/docs/resources/lambda_event_source_mapping)
- [AWS CreateEventSourceMapping](https://docs.aws.amazon.com/lambda/latest/api/API_CreateEventSourceMapping.html)
- [SQS mapping parameters](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-parameters.html)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.54.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.54.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_lambda_event_source_mapping.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_amazon_managed_kafka_event_source_config"></a> [amazon\_managed\_kafka\_event\_source\_config](#input\_amazon\_managed\_kafka\_event\_source\_config) | MSK consumer group and optional schema registry settings. | <pre>object({<br/>    consumer_group_id = optional(string)<br/>    schema_registry_config = optional(object({<br/>      access_config            = optional(set(object({ type = optional(string), uri = optional(string) })), [])<br/>      event_record_format      = optional(string)<br/>      schema_registry_uri      = optional(string)<br/>      schema_validation_config = optional(set(object({ attribute = optional(string) })), [])<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_batch_size"></a> [batch\_size](#input\_batch\_size) | Maximum records per invocation. Legacy numeric string input; effective default remains 10 for every source. | `string` | `"10"` | no |
| <a name="input_bisect_batch_on_function_error"></a> [bisect\_batch\_on\_function\_error](#input\_bisect\_batch\_on\_function\_error) | Split failed batches for stream/Kafka sources. | `bool` | `null` | no |
| <a name="input_destination_config"></a> [destination\_config](#input\_destination\_config) | Destination for discarded stream/Kafka records. Caller provisions destination and permissions. | <pre>object({<br/>    on_failure = optional(object({ destination_arn = string }))<br/>  })</pre> | `null` | no |
| <a name="input_document_db_event_source_config"></a> [document\_db\_event\_source\_config](#input\_document\_db\_event\_source\_config) | DocumentDB database, optional collection and full-document mode. | <pre>object({<br/>    database_name   = string<br/>    collection_name = optional(string)<br/>    full_document   = optional(string, "Default")<br/>  })</pre> | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether polling is enabled. Legacy boolean string input; accepts convertible booleans. | `string` | `"true"` | no |
| <a name="input_event_source_arn"></a> [event\_source\_arn](#input\_event\_source\_arn) | Kinesis, DynamoDB stream, SQS, MQ, MSK or DocumentDB ARN; omit for self-managed Kafka. | `string` | `null` | no |
| <a name="input_filter_criteria"></a> [filter\_criteria](#input\_filter\_criteria) | Up to ten JSON event filters (six through ten require an increased service quota). | <pre>object({<br/>    filter = optional(set(object({ pattern = optional(string) })), [])<br/>  })</pre> | `null` | no |
| <a name="input_function_name"></a> [function\_name](#input\_function\_name) | Name or ARN of the subscribing Lambda function. | `string` | n/a | yes |
| <a name="input_function_response_types"></a> [function\_response\_types](#input\_function\_response\_types) | Empty or ReportBatchItemFailures; the function must implement partial failure responses. | `set(string)` | `[]` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | Existing customer managed key ARN for encrypting filter criteria. No key is created. | `string` | `null` | no |
| <a name="input_maximum_batching_window_in_seconds"></a> [maximum\_batching\_window\_in\_seconds](#input\_maximum\_batching\_window\_in\_seconds) | Integer batching window 0..300; null preserves source defaults (including 500ms). | `number` | `null` | no |
| <a name="input_maximum_record_age_in_seconds"></a> [maximum\_record\_age\_in\_seconds](#input\_maximum\_record\_age\_in\_seconds) | Discard old stream/Kafka records: -1 for infinite, or integer 60..604800 seconds. | `number` | `null` | no |
| <a name="input_maximum_retry_attempts"></a> [maximum\_retry\_attempts](#input\_maximum\_retry\_attempts) | Stream/Kafka retry limit: integer -1 (infinite) through 10000. | `number` | `null` | no |
| <a name="input_metrics_config"></a> [metrics\_config](#input\_metrics\_config) | Enhanced event source metrics: EventCount, ErrorCount and/or KafkaMetrics. | `object({ metrics = set(string) })` | `null` | no |
| <a name="input_parallelization_factor"></a> [parallelization\_factor](#input\_parallelization\_factor) | Concurrent batches per Kinesis/DynamoDB shard, integer 1..10. | `number` | `null` | no |
| <a name="input_provisioned_poller_config"></a> [provisioned\_poller\_config](#input\_provisioned\_poller\_config) | Dedicated Kafka/SQS pollers: minimum 1..200 (SQS 2..200), maximum 1..2000, optional group name. | <pre>object({<br/>    minimum_pollers   = optional(number)<br/>    maximum_pollers   = optional(number)<br/>    poller_group_name = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_queues"></a> [queues](#input\_queues) | One MQ destination queue name, 1..1000 characters; empty for other sources. | `list(string)` | `[]` | no |
| <a name="input_region"></a> [region](#input\_region) | Resource region override; null inherits the provider region. | `string` | `null` | no |
| <a name="input_scaling_config"></a> [scaling\_config](#input\_scaling\_config) | SQS maximum concurrency, integer >=2. An empty object clears the setting. | `object({ maximum_concurrency = optional(number) })` | `null` | no |
| <a name="input_self_managed_event_source"></a> [self\_managed\_event\_source](#input\_self\_managed\_event\_source) | Self-managed Kafka bootstrap endpoints (KAFKA\_BOOTSTRAP\_SERVERS => comma-separated brokers). Conflicts with an ARN source. | `object({ endpoints = map(string) })` | `null` | no |
| <a name="input_self_managed_kafka_event_source_config"></a> [self\_managed\_kafka\_event\_source\_config](#input\_self\_managed\_kafka\_event\_source\_config) | Self-managed Kafka consumer group and optional schema registry settings. | <pre>object({<br/>    consumer_group_id = optional(string)<br/>    schema_registry_config = optional(object({<br/>      access_config            = optional(set(object({ type = optional(string), uri = optional(string) })), [])<br/>      event_record_format      = optional(string)<br/>      schema_registry_uri      = optional(string)<br/>      schema_validation_config = optional(set(object({ attribute = optional(string) })), [])<br/>    }))<br/>  })</pre> | `null` | no |
| <a name="input_source_access_configuration"></a> [source\_access\_configuration](#input\_source\_access\_configuration) | Source authentication and network access configuration; existing secrets/network resources only. | `set(object({ type = string, uri = string }))` | `[]` | no |
| <a name="input_starting_position"></a> [starting\_position](#input\_starting\_position) | LATEST, TRIM\_HORIZON or AT\_TIMESTAMP; empty string omits the argument. Not supported by SQS or MQ. | `string` | `""` | no |
| <a name="input_starting_position_timestamp"></a> [starting\_position\_timestamp](#input\_starting\_position\_timestamp) | RFC3339 starting timestamp for AT\_TIMESTAMP; empty string omits the argument. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Mapping tags merged over Name=function\_name; caller Name wins. | `map(string)` | `{}` | no |
| <a name="input_timeouts"></a> [timeouts](#input\_timeouts) | Optional create, update and delete operation timeout overrides. | <pre>object({<br/>    create = optional(string)<br/>    update = optional(string)<br/>    delete = optional(string)<br/>  })</pre> | `null` | no |
| <a name="input_topics"></a> [topics](#input\_topics) | One Kafka topic, 1..249 characters; empty for other sources. | `set(string)` | `[]` | no |
| <a name="input_tumbling_window_in_seconds"></a> [tumbling\_window\_in\_seconds](#input\_tumbling\_window\_in\_seconds) | Kinesis/DynamoDB aggregation window, integer 0..900. | `number` | `null` | no |
| <a name="input_use_resource_timeout_for_propagation"></a> [use\_resource\_timeout\_for\_propagation](#input\_use\_resource\_timeout\_for\_propagation) | Use operation timeouts for mapping propagation instead of the provider propagation timeout. | `bool` | `false` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | Event source mapping ARN. |
| <a name="output_batch_size"></a> [batch\_size](#output\_batch\_size) | Effective numeric batch size. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Effective boolean polling setting. |
| <a name="output_event_source_arn"></a> [event\_source\_arn](#output\_event\_source\_arn) | Event source ARN; null for self-managed Kafka. |
| <a name="output_function_arn"></a> [function\_arn](#output\_function\_arn) | Resolved Lambda function ARN. |
| <a name="output_function_response_types"></a> [function\_response\_types](#output\_function\_response\_types) | Configured partial batch response types. |
| <a name="output_id"></a> [id](#output\_id) | Event source mapping identifier (UUID). |
| <a name="output_last_modified"></a> [last\_modified](#output\_last\_modified) | Provider-reported last modification timestamp. |
| <a name="output_last_processing_result"></a> [last\_processing\_result](#output\_last\_processing\_result) | Provider-reported last processing result, not a delivery guarantee. |
| <a name="output_maximum_batching_window_in_seconds"></a> [maximum\_batching\_window\_in\_seconds](#output\_maximum\_batching\_window\_in\_seconds) | Configured integer batching window; null delegates to source defaults. |
| <a name="output_state"></a> [state](#output\_state) | Provider-reported mapping state. |
| <a name="output_state_transition_reason"></a> [state\_transition\_reason](#output\_state\_transition\_reason) | Provider-reported reason for the last state transition. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Mapping tags including provider default tags. |
| <a name="output_uuid"></a> [uuid](#output\_uuid) | Event source mapping UUID, identical to id. |
<!-- END_TF_DOCS -->
