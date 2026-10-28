# DynamoDB tables

Manages only `aws_dynamodb_table.this`, keyed by stable logical table identity.
This module exposes the complete configurable table resource, including ordered
global secondary index key schemas, replicas/witness, restores, S3 import,
per-table region and operation timeouts. An empty `tables` map creates nothing.

## Prerequisites and versions

- Terraform >= 1.3.0 or a compatible OpenTofu release. Optional object defaults
  establish the language floor; resource configuration uses no post-fork features.
- `hashicorp/aws >= 6.38.0`: `restore_backup_arn` establishes this exact floor.
  Earlier included features are replica consistency (6.3), replica deletion
  protection (6.9), warm throughput (6.13), witness (6.22), and ordered index
  key schemas (6.29).
- Native mocked tests require OpenTofu >= 1.9 (default runner) or Terraform >= 1.7.
  This test-runner requirement does not raise the module language floor.
- Configure the AWS provider externally. Provision external customer-managed
  keys, S3 import objects, permissions, alarms, and backup schedules separately
  when needed. No customer-managed key is required for the baseline.
- Global-table regions must meet the service's supported region-group rules.
  When `region` is omitted, the provider selects the source region; callers
  must ensure replicas/witness differ from that provider region.

The inventory was checked against the immutable
[6.38.0 resource source](https://github.com/hashicorp/terraform-provider-aws/blob/v6.38.0/internal/service/dynamodb/table.go),
[6.38.0 documentation source](https://github.com/hashicorp/terraform-provider-aws/blob/v6.38.0/website/docs/r/dynamodb_table.html.markdown),
[registry documentation](https://registry.terraform.io/providers/hashicorp/aws/6.38.0/docs/resources/dynamodb_table)
and the released 6.70.0 source. Provider defaults are not the module's secure defaults.

## Issue #537: webhook table

Pin `source` to the eventual released tag or reviewed commit before production
use; replace `RELEASE_TAG` below with that actual version, not a moving branch.

```hcl
module "tables" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/dynamodb/table?ref=RELEASE_TAG"

  tables = {
    webhook = {
      name         = "webhook"
      billing_mode = "PAY_PER_REQUEST"
      hash_key     = "pk"
      attribute    = [{ name = "pk", type = "S" }]
      ttl = {
        attribute_name = "ttl"
        enabled        = true
      }
      point_in_time_recovery = { enabled = true }
      server_side_encryption = { enabled = true }
    }
  }
  tags = { Team = "platform" }
}
```

`ttl` is an item expiry field, **not** an attribute definition unless it is
also an indexed key. Only table/index keys belong in `attribute`. The
baseline creates no key, alias, identity policy, autoscaling or monitoring resource.

## Multiple tables from YAML

One module call manages any number of tables; map keys are state identities
and must remain stable. The explicit `name` is the physical AWS table name.

```hcl
module "tables" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/dynamodb/table?ref=RELEASE_TAG"
  tables = yamldecode(file("${path.module}/tables.yaml"))
  tags   = { Team = "platform" }
}
```

`tables.yaml`:

```yaml
webhook:
  name: webhook
  hash_key: pk
  attribute:
    - name: pk
      type: S
  ttl:
    enabled: true
    attribute_name: ttl
audit:
  name: audit
  hash_key: event_id
  attribute:
    - name: event_id
      type: S
  tags:
    Name: audit-events
```

## Advanced indexes and capacity

```hcl
module "indexed_tables" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/dynamodb/table?ref=RELEASE_TAG"
  tables = {
    events = {
      name           = "events"
      hash_key       = "pk"
      billing_mode   = "PROVISIONED"
      read_capacity  = 5
      write_capacity = 5
      attribute = [
        { name = "pk", type = "S" },
        { name = "tenant", type = "S" },
        { name = "created_at", type = "N" }
      ]
      global_secondary_index = [{
        name = "by-tenant"
        key_schema = [
          { attribute_name = "tenant", key_type = "HASH" },
          { attribute_name = "created_at", key_type = "RANGE" }
        ]
        projection_type = "ALL"
        read_capacity   = 5
        write_capacity  = 5
      }]
    }
  }
}
```

## Input and output design

- `billing_mode` defaults to `PAY_PER_REQUEST`; provisioned normal creation and
  import require positive integer read/write capacities on the table and each
  global secondary index. Restores may omit capacities inherited from the source.
- `table_class` defaults to `STANDARD`. `region` defaults to the provider's
  region. `deletion_protection_enabled` defaults to true.
- Table and replica point-in-time recovery are enabled by default. Table
  `recovery_period_in_days` is optional (provider default 35); explicit retention
  must be an integer 1..35.
- Table server-side encryption defaults to enabled with no customer key:
  AWS-managed Key Management Service encryption. `kms_key_arn` accepts an
  externally managed key. `enabled=false` selects AWS-owned encryption, not
  plaintext. This module never creates keys implicitly.
- TTL is omitted by default. Enabled TTL requires a nonempty `attribute_name`;
  disabled TTL may retain its previous name so an existing TTL can be disabled.
- Streams default to disabled. Enabled streams require a view
  (`KEYS_ONLY`, `NEW_IMAGE`, `OLD_IMAGE`, `NEW_AND_OLD_IMAGES`). A view without
  streams is rejected.
- `attribute`, indexes and replicas use sets. Index `key_schema` is deliberately
  an **ordered list** (1..4 HASH entries and 0..4 RANGE entries, distinct names).
  Legacy global-index `hash_key`/`range_key` inputs remain accepted, but cannot
  coexist with a nonempty ordered schema. They produce provider deprecation
  warnings; new callers should use `key_schema`.
- Index names are distinct across global/local indexes. Local indexes require
  the table sort key. `INCLUDE` requires non-key attributes; `ALL`/`KEYS_ONLY`
  prohibit them. Non-key fields are not added to `attribute`.
- Table/index on-demand throughput caps are -1 (unlimited) or positive
  integers, available only with `PAY_PER_REQUEST`. Warm reads/writes are
  independently optional integers >=12000/>=4000.
- Replicas default to `EVENTUAL`, recovery/deletion protection/tag propagation
  true; these true defaults are deliberate module choices. EVENTUAL requires
  streams. STRONG requires two remote replicas, or one remote replica and one
  witness, and forbids enabled TTL and local secondary indexes. STRONG alone
  does not require streams. Replica modes must agree. Explicit source, replica,
  and witness regions must be distinct; no region data source is queried.
- Restore selectors `restore_backup_arn`, `restore_source_name`, and
  `restore_source_table_arn` are mutually exclusive and each conflicts with
  `import_table`. Restores may omit partition key and attributes. PITR time
  options require a source name/ARN, not a backup; explicit UTC RFC3339 time
  conflicts with latest=true.
- S3 imports support CSV/DYNAMODB_JSON/ION, optional GZIP/ZSTD/NONE compression,
  bucket/owner/key-prefix, and optional CSV delimiter/header set. CSV options
  cannot accompany another input format. Imports require creation key schema.
- `timeouts` optionally overrides provider create/update/delete durations.
  Nullable advanced blocks are omitted. The PITR/encryption object defaults
  are `{}`, so explicit null also receives the safe optional-object defaults;
  use `{ enabled = false }` for deliberate opt-outs.
- Tags merge `{Name = physical_name}`, shared tags, then per-table tags;
  caller overrides win. `tags_all` includes provider default tags.
- `table_names`, `table_ids`, `table_arns`, `stream_arns`, `stream_labels`,
  `tags_all`, `replicas` and `tables` retain logical table keys. Disabled table
  streams are null. `replicas[table][region]` includes ARN and nullable
  stream ARN/label. Empty replica stream strings normalize to null.
  `tables[table]` aggregates `name`, `id`, `arn`, `stream_arn`, `stream_label`,
  `tags_all`, and `replicas`. IDs/names are physical provider identifiers, not keys.

## Adoption without recreation

For an object **already managed in the same state**, replace the native block
with the matching module configuration above and add this caller-side move:

```hcl
moved {
  from = aws_dynamodb_table.webhook
  to   = module.tables.aws_dynamodb_table.this["webhook"]
}
```

For an existing table **not yet in state**, configure the module and import by
physical table name instead (do not import an already-managed object twice):

```hcl
import {
  to = module.tables.aws_dynamodb_table.this["webhook"]
  id = "webhook"
}
```

Declarative import requires Terraform >=1.5 or OpenTofu >=1.6. The module
language floor remains 1.3. The equivalent command is:

```sh
tofu import 'module.tables.aws_dynamodb_table.this["webhook"]' webhook
```

Preserve the original physical name, billing, keys, index definitions, TTL,
streams, encryption, recovery/deletion protection and tags. Override new-module
secure defaults when the existing table differs; do not combine an address-only
move with an unreviewed behavior change. Inspect a real plan against the
consumer's own state and require no unintended destruction/replacement.
Mocked module tests do not certify any production state.

## Replacement, ownership and release notes

This new module is additive. The combined issue #537 also increases existing
modules' tool/provider floors and therefore requires the repository's major
release assessment; do not describe the entire combined release as non-breaking.

Name, primary-key, local-index and import/restore selector changes can require
replacement. Review all plans. **Do not decrease warm throughput:** at the
6.38.0 floor decreases may force replacement; provider 6.57.1+ instead reports a
planning error. The floor is not inflated to hide this service restriction.

There are no lifecycle drift ignores. This module owns configured capacities,
indexes, TTL, encryption and replicas; external autoscaling or separately managed
replica/index resources must not simultaneously manage these same settings.
Compose external autoscaling deliberately with an agreed ownership model rather
than hiding capacity drift.

## Offline verification

```sh
tofu init -backend=false
tofu validate
tofu test
tofu fmt -check -diff -recursive
terraform-docs markdown table --output-file README.md --output-mode inject .
```

Tests use mocked providers and fabricated identifiers only. No AWS calls,
credentials, backend or production state are required.
The module validates on Terraform 1.10.0. Its native test runner does not
populate the nested replica computed fields from these OpenTofu mock defaults;
the two exact replica-output runs fail there (including retained computed
metadata across mock updates). The unchanged assertions pass on OpenTofu with
both the minimum and current provider. Treat this as a test-runner limitation,
not evidence of live service behavior or a reason to relax the output contract.

Repository-configured Checkov reports `CKV_AWS_28` and `CKV_AWS_119` for this
resource. The former does not resolve the dynamic point-in-time recovery block
and its enabled typed default; native tests verify it is enabled. The latter
requires a customer-managed key, whereas the approved baseline deliberately
uses encrypted AWS-managed key storage. Callers can supply an external customer
key when policy requires one. Neither finding is suppressed; these
caller-configurability/static-analysis dispositions require maintainer review.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.38.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.38.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_dynamodb_table.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_tables"></a> [tables](#input\_tables) | Tables keyed by stable logical identity. Only indexed keys belong in attribute; TTL/item fields do not. Optional advanced blocks are omitted when null. | <pre>map(object({<br/>    name                        = string<br/>    region                      = optional(string)<br/>    billing_mode                = optional(string, "PAY_PER_REQUEST")<br/>    hash_key                    = optional(string)<br/>    range_key                   = optional(string)<br/>    attribute                   = optional(set(object({ name = string, type = string })), [])<br/>    read_capacity               = optional(number)<br/>    write_capacity              = optional(number)<br/>    deletion_protection_enabled = optional(bool, true)<br/>    table_class                 = optional(string, "STANDARD")<br/>    tags                        = optional(map(string), {})<br/>    stream_enabled              = optional(bool, false)<br/>    stream_view_type            = optional(string)<br/>    ttl = optional(object({<br/>      attribute_name = optional(string)<br/>      enabled        = optional(bool, false)<br/>    }))<br/>    point_in_time_recovery = optional(object({<br/>      enabled                 = optional(bool, true)<br/>      recovery_period_in_days = optional(number)<br/>    }), {})<br/>    server_side_encryption = optional(object({<br/>      enabled     = optional(bool, true)<br/>      kms_key_arn = optional(string)<br/>    }), {})<br/>    on_demand_throughput = optional(object({<br/>      max_read_request_units  = optional(number)<br/>      max_write_request_units = optional(number)<br/>    }))<br/>    warm_throughput = optional(object({<br/>      read_units_per_second  = optional(number)<br/>      write_units_per_second = optional(number)<br/>    }))<br/>    global_secondary_index = optional(set(object({<br/>      name               = string<br/>      projection_type    = string<br/>      hash_key           = optional(string)<br/>      range_key          = optional(string)<br/>      key_schema         = optional(list(object({ attribute_name = string, key_type = string })), [])<br/>      non_key_attributes = optional(set(string), [])<br/>      read_capacity      = optional(number)<br/>      write_capacity     = optional(number)<br/>      on_demand_throughput = optional(object({<br/>        max_read_request_units  = optional(number)<br/>        max_write_request_units = optional(number)<br/>      }))<br/>      warm_throughput = optional(object({<br/>        read_units_per_second  = optional(number)<br/>        write_units_per_second = optional(number)<br/>      }))<br/>    })), [])<br/>    local_secondary_index = optional(set(object({<br/>      name               = string<br/>      range_key          = string<br/>      projection_type    = string<br/>      non_key_attributes = optional(list(string), [])<br/>    })), [])<br/>    replica = optional(set(object({<br/>      region_name                 = string<br/>      kms_key_arn                 = optional(string)<br/>      point_in_time_recovery      = optional(bool, true)<br/>      propagate_tags              = optional(bool, true)<br/>      deletion_protection_enabled = optional(bool, true)<br/>      consistency_mode            = optional(string, "EVENTUAL")<br/>    })), [])<br/>    global_table_witness     = optional(object({ region_name = string }))<br/>    restore_backup_arn       = optional(string)<br/>    restore_source_name      = optional(string)<br/>    restore_source_table_arn = optional(string)<br/>    restore_date_time        = optional(string)<br/>    restore_to_latest_time   = optional(bool)<br/>    import_table = optional(object({<br/>      input_format           = string<br/>      input_compression_type = optional(string)<br/>      s3_bucket_source = object({<br/>        bucket       = string<br/>        bucket_owner = optional(string)<br/>        key_prefix   = optional(string)<br/>      })<br/>      input_format_options = optional(object({<br/>        csv = optional(object({<br/>          delimiter   = optional(string)<br/>          header_list = optional(set(string))<br/>        }))<br/>      }))<br/>    }))<br/>    timeouts = optional(object({<br/>      create = optional(string)<br/>      update = optional(string)<br/>      delete = optional(string)<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Shared table tags; per-table tags override these and the physical-name Name tag. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_replicas"></a> [replicas](#output\_replicas) | Replica computed metadata keyed by table then replica region; empty stream fields are null. |
| <a name="output_stream_arns"></a> [stream\_arns](#output\_stream\_arns) | Stream ARNs keyed by logical identity; null when streams are disabled. |
| <a name="output_stream_labels"></a> [stream\_labels](#output\_stream\_labels) | Stream labels keyed by logical identity; null when streams are disabled. |
| <a name="output_table_arns"></a> [table\_arns](#output\_table\_arns) | Table ARNs keyed by logical identity. |
| <a name="output_table_ids"></a> [table\_ids](#output\_table\_ids) | Provider table identifiers keyed by logical identity. |
| <a name="output_table_names"></a> [table\_names](#output\_table\_names) | Physical table names keyed by logical identity. |
| <a name="output_tables"></a> [tables](#output\_tables) | Aggregate table identity, stream, tags and replica metadata keyed by logical identity. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | Effective provider and caller tags keyed by logical identity. |
<!-- END_TF_DOCS -->
