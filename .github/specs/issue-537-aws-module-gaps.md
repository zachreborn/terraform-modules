# Spec: Close module gaps for DynamoDB, SQS, Lambda, and HTTP APIs
**Issue:** #537
**Status:** Draft - pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
[Issue #537](https://github.com/zachreborn/terraform-modules/issues/537)
identifies eight native resource instances that cannot yet be adopted without
losing behavior: a DynamoDB table, two SQS queues, a Lambda event-source mapping,
and an HTTP API, integration, route, and stage. The comparison baseline is
v17.4.0, commit `2869aa853c0fbd08a48500adadbc3130ea18b470`.

There is no DynamoDB table module. SQS always creates a KMS key/alias, references
undeclared identity/region data, and has incomplete, regex-based validations.
The mapping omits batching-window and partial-batch response controls and has
no outputs. API v2 accesses attributes missing from its declared object types,
misreads nested JWT/domain configuration, and ignores some declared inputs.
None of these three existing modules currently provides the required native
test suite.

This is behavior-preserving adoption, not an encryption redesign. Workstreams
may land independently, but the tracking issue is complete only after all four
meet this specification. Follow root `AGENTS.md`, `modules/module_template/`,
and the native examples in `modules/aws/organizations/tests/`.

## 2. Non-goals
- No downstream application changes, live imports, production state access,
  deployment, secret values, credentials, or operational data.
- No alarms, Secrets Manager containers, Lambda functions/permissions, IAM
  execution roles, CloudWatch log groups, certificates, DNS, or API mappings
  created implicitly. Callers compose existing domain-specific modules.
- No forced customer-managed encryption, forced IAM/JWT authentication, logging
  of webhook tokens, or queue/table/API recreation as an adoption technique.
- No API Gateway REST API changes, DynamoDB autoscaling/backup scheduling
  orchestration, or replacement of application-level token authentication.
- No resource implementation in this spec PR; only this specification changes.

## 3. Affected module path(s)
- `modules/aws/dynamodb/table/` (new): `main.tf`, `variables.tf`, `outputs.tf`,
  `README.md`, and `tests/*.tftest.hcl`, based on the module template.
- `modules/aws/sqs_queue/` (existing): the same four files and new `tests/`.
- `modules/aws/lambda_event_source_mapping/` (existing): the same files and new
  `tests/`.
- `modules/aws/api_gateway/v2/` (existing): the same files and new `tests/`.
- `modules/aws/kms/` is reused unchanged as a child, not duplicated inline.
- Any implementation release/migration notes belong in the affected READMEs;
  release-please remains the owner of generated repository release history.

## 4. Proposed design
**Signatures only - no full implementations.**

### Interface notation and common contract
In the signatures below, `T? = value` denotes an optional value of type `T`
with that default; `T?` without a value defaults to null. Object and collection
types are concrete HCL types, not `any`. Named object shapes below are
documentation abbreviations: HCL must inline them, not introduce nonexistent
type aliases. Every input needs a description matching the stated purpose.
Computed provider attributes are outputs, not configurable inputs.

Use provider schema, not AWS API names, for the final attribute inventory.
Expose every configurable argument of the managed resources, including region
and timeouts, and all useful computed attributes. Optional advanced blocks
must be omitted when null, never emitted as empty invalid blocks. Empty maps
must create no instances; collection keys are stable state identities.

The existing SQS and mapping modules remain single-resource leaves to preserve
their resource addresses. Their READMEs must provide map/YAML-driven caller
`for_each` module examples, including two queues and multiple mappings; callers
must not duplicate module declarations to scale. API v2 already uses keyed
maps; DynamoDB uses a first-class table map.

#### Provider/tool versions and authoritative references
All four modules use `source = "hashicorp/aws"`. Declare module-specific floors,
with one-line comments identifying the feature that requires each:
- Language floor `required_version >= 1.3.0` where optional object defaults are
  used. `moved` requires 1.1 and preconditions 1.2, both covered by 1.3.
  Do not use cross-variable input validations requiring Terraform 1.9;
  cross-input checks belong in resource preconditions.
- SQS: AWS `>= 6.8.0`, because complete queue coverage accepts
  `max_message_size` through 1048576, added in 6.8.0.
- DynamoDB: AWS `>= 6.38.0` for `restore_backup_arn`; this also covers replica
  consistency (6.3.0), replica deletion protection (6.9.0), warm throughput
  (6.13.0), global-table witness (6.22.0), and GSI key schemas (6.29.0).
- Mapping: AWS `>= 6.54.0` for configurable timeouts and
  `use_resource_timeout_for_propagation`; this includes Kafka schema registries
  (6.16.0) and poller group names (6.28.0). The two issue-specific additions
  alone exist in 6.0.0, but complete resource coverage requires the higher floor.
- API v2: AWS `>= 6.29.0` for domain `routing_mode`; API/domain IP-address
  controls exist since 5.96.0 and per-resource region since 6.0.0.
- OpenTofu is the default runner; mocked native tests require OpenTofu 1.9+
  (Terraform 1.7+ for an equivalent optional test run). Test-runner versions do
  not justify inflating the modules' language floor.

Schema references consulted for this specification:
- [SQS source at 6.0.0](https://github.com/hashicorp/terraform-provider-aws/blob/v6.0.0/internal/service/sqs/queue.go)
  and [current queue documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue).
- [AWS provider changelog](https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md):
  SQS message-size increase in 6.8.0.
- [DynamoDB table source](https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/service/dynamodb/table.go)
  and [table documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table).
- [Lambda mapping source](https://github.com/hashicorp/terraform-provider-aws/blob/main/internal/service/lambda/event_source_mapping.go)
  and [mapping documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lambda_event_source_mapping).
- [API Gateway v2 source directory](https://github.com/hashicorp/terraform-provider-aws/tree/main/internal/service/apigatewayv2)
  and [integration documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_integration),
  [route documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_route),
  [stage documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_stage),
  [authorizer documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer),
  [domain documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_domain_name).
- [Terraform module refactoring](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
  for retaining resource identities across the KMS child-module move.
Immutable coverage baselines are
[DynamoDB 6.38.0](https://github.com/hashicorp/terraform-provider-aws/blob/v6.38.0/internal/service/dynamodb/table.go),
[mapping 6.54.0](https://github.com/hashicorp/terraform-provider-aws/blob/v6.54.0/internal/service/lambda/event_source_mapping.go),
and [API v2 6.29.0](https://github.com/hashicorp/terraform-provider-aws/tree/v6.29.0/internal/service/apigatewayv2).
These signatures reflect released provider 6.70.0, not unreleased additions.
For Lambda source semantics, also consult
[CreateEventSourceMapping](https://docs.aws.amazon.com/lambda/latest/api/API_CreateEventSourceMapping.html)
and [SQS mapping parameters](https://docs.aws.amazon.com/lambda/latest/dg/services-sqs-parameters.html).

### `variables.tf`: DynamoDB table
`tables: map(object(Table)) = {}` is keyed by stable logical identity, with
explicit physical names. `tags: map(string) = {}` supplies shared tags.
The Table shape is:
- `name: string`: explicit physical table name, not a derived prefix.
- `region: string?`, `billing_mode: string? = "PAY_PER_REQUEST"`,
  `hash_key: string?`, `range_key: string?`,
  `attribute: set(object({name=string,type=string}))? = []`: region, billing,
  table key and indexed attribute definitions. Hash/attributes are nullable to
  allow provider-supported restores/imports; normal creation requires keys.
- `read_capacity: number?`, `write_capacity: number?`: provisioned units.
- `deletion_protection_enabled: bool? = true`,
  `table_class: string? = "STANDARD"`, `tags: map(string)? = {}`.
- `stream_enabled: bool? = false`, `stream_view_type: string?`.
- `ttl: object({attribute_name=optional(string),
  enabled=optional(bool,false)})?`: expiry, omitted by default.
- `point_in_time_recovery: object({enabled=optional(bool,true),
  recovery_period_in_days=optional(number)})? = {}`: enabled by default,
  provider-default 35-day retention.
- `server_side_encryption: object({enabled=optional(bool,true),
  kms_key_arn=optional(string)})? = {}`: AWS-managed KMS by default without
  creating a customer key. False selects AWS-owned encryption, not plaintext.
- `on_demand_throughput: object({max_read_request_units=optional(number),
  max_write_request_units=optional(number)})?`: request caps.
- `warm_throughput: object({read_units_per_second=optional(number),
  write_units_per_second=optional(number)})?`: warm capacity.
- `global_secondary_index: set(object(GSI))? = []`,
  `local_secondary_index: set(object(LSI))? = []`,
  `replica: set(object(Replica))? = []`,
  `global_table_witness: object({region_name=string})?`.
- `restore_backup_arn: string?`, `restore_source_name: string?`,
  `restore_source_table_arn: string?`, `restore_date_time: string?`,
  `restore_to_latest_time: bool?`: mutually compatible restore selectors.
- `import_table: object(Import)?`: S3 bulk import.
- `timeouts: object({create=optional(string),update=optional(string),
  delete=optional(string)})?`: provider timeout overrides.

Nested shapes:
- GSI: `name: string`, `projection_type: string`, `hash_key: string?`,
  `range_key: string?`, `key_schema: list(object({attribute_name=string,
  key_type=string}))? = []`, `non_key_attributes: set(string)? = []`,
  `read_capacity: number?`, `write_capacity: number?`,
  `on_demand_throughput` and `warm_throughput` with the table-level shapes.
  Ordered `key_schema` supports composite keys; do not convert it to a set.
  Legacy hash/range keys remain accepted but conflict with nonempty key_schema.
- LSI: `name: string`, `range_key: string`, `projection_type: string`,
  `non_key_attributes: list(string)? = []`.
- Replica: `region_name: string`, `kms_key_arn: string?`,
  `point_in_time_recovery: bool? = true`, `propagate_tags: bool? = true`,
  `deletion_protection_enabled: bool? = true`,
  `consistency_mode: string? = "EVENTUAL"`. Secure true defaults are deliberate
  new-module choices, not claimed provider defaults.
- Import: `input_format: string`, `input_compression_type: string?`,
  `s3_bucket_source: object({bucket=string,bucket_owner=optional(string),
  key_prefix=optional(string)})`, and
  `input_format_options: object({csv=optional(object({
  delimiter=optional(string),header_list=optional(set(string))}))})?`.

All table-local validations belong to `var.tables`. Validate:
- Billing PAY_PER_REQUEST/PROVISIONED; class STANDARD/STANDARD_INFREQUENT_ACCESS;
  attribute type S/N/B; projection ALL/KEYS_ONLY/INCLUDE; documented stream
  views, consistency EVENTUAL/STRONG, import formats CSV/DYNAMODB_JSON/ION and
  compression GZIP/ZSTD/NONE.
- Normal creation requires partition key and complete indexed attributes;
  attribute names must be unique, referenced, and not unused item fields.
  `ttl` is not an attribute definition unless it is also an indexed key.
  Index names are distinct; LSI requires a base sort key.
- Provisioned normal tables/GSIs require both positive integer capacities;
  on-demand mode rejects provisioned units. Caps are -1 or positive integers
  and apply only to on-demand mode. Recovery days are integers 1..35; warm
  reads are integers >=12000 and writes >=4000 where provided.
- Enabled TTL requires a nonempty attribute name; disabled TTL may retain its
  previous attribute name to permit disabling an already configured TTL.
  Enabled streams require a valid view; a view without streams is invalid.
  INCLUDE needs non-key fields; ALL/KEYS_ONLY must not supply them.
- GSI ordered schemas need HASH entries, at most four HASH and four RANGE
  entries, distinct attribute names, valid HASH/RANGE values, and no legacy
  key fields. Validate references against the table's attribute definitions.
- Import conflicts separately with every restore source; backup/name/source
  ARN selectors are mutually exclusive. Explicit restore timestamp conflicts
  with latest=true and must be valid UTC RFC3339; PITR options need a PITR
  source. CSV options are only valid for CSV.
- Replica regions and witness region must be distinct; reject the source
  region when explicitly known. Replica consistency modes must agree.
  STRONG requires two replicas, or one replica plus one witness; it forbids
  enabled TTL and LSIs. EVENTUAL replicas require streams; do not incorrectly
  require streams for STRONG solely because it is a global table.

### `outputs.tf`: DynamoDB table
Add `table_names`, `table_ids`, `table_arns`, `stream_arns`, and `stream_labels`
as maps keyed by table logical key; stream values are nullable when disabled.
`tags_all` is `map(map(string))`.
`replicas` is `map(map(object({arn=string,stream_arn=string,
stream_label=string})))`, keyed by table then region, with nullable stream
fields. `tables` is a keyed aggregate of these same fields. ID/name reflect
the provider table identifier, not the logical map key.

### `main.tf`: DynamoDB table
`aws_dynamodb_table.this` uses `for_each = tables`; nested blocks preserve their
declared collection semantics and null/set branches. No KMS, alarms, IAM,
autoscaling or log resources are created inline. Tags merge Name=physical
table name, shared tags, then table tags (caller override wins).
Do not add lifecycle ignores for billing, capacity, keys or TTL. Document
ForceNew name/key/LSI/restore changes and external autoscaling ownership.
Warm-throughput decreases can cause replacement at the 6.38.0 floor (changed
to a planning error in 6.57.1); warn against decreases and require plan review,
rather than inflating the true feature-introduction floor.

### `variables.tf`: SQS
Retain every existing variable name and existing default. Normalize the existing
numeric string inputs to numbers: `delay_seconds: number = 0`,
`visibility_timeout_seconds: number = 30`, and explicitly type
`message_retention_seconds: number = 345600`. Numeric strings remain accepted
by HCL conversion; invalid strings and fractions must fail rather than match
part of a regex. Retain `fifo_queue: bool = false`, required `name: string`
(explicit null may select generated naming), `tags: map(string) = {}`, and
`kms_data_key_reuse_period_seconds: number = 300`.

Add:
- `create_kms_key: bool = true`: retain legacy customer-managed key creation.
- `kms_master_key_id: string?`: use an existing key ID/ARN/alias, without creating
  another key; requires `create_kms_key = false`.
- `sqs_managed_sse_enabled: bool?`: provider SQS-owned encryption selection.
  Required example explicitly sets true and disables key creation.
- `redrive_policy: string?`: JSON containing `deadLetterTargetArn` and integer
  `maxReceiveCount`; retain exact consumer delivery semantics.
- `redrive_allow_policy: string?`: DLQ permission JSON, optionally restricting
  source queue ARNs. Do not manage the same policy using a second resource.
- `policy: string?`: queue access-policy JSON, with explicit IAM policy version.
- `name_prefix: string?`: alternative generated queue naming.
- `content_based_deduplication: bool? = false`, `deduplication_scope: string?`,
  `fifo_throughput_limit: string?`: FIFO behavior.
- `max_message_size: number? = 262144`: accepted message bytes.
- `receive_wait_time_seconds: number? = 0`: long-polling wait.
- `region: string?`: queue and child-key region override.
- `timeouts: object({create=optional(string), update=optional(string),
  delete=optional(string)})?`: provider operation timeout overrides.
- `key_policy: string?`: optional explicit child KMS policy; otherwise derive
  the policy with declared partition/account/region data sources.

Retain all `key_*` inputs (`key_customer_master_key_spec`,
`key_description`, `key_deletion_window_in_days`, `key_enable_key_rotation`,
`key_usage`, `key_is_enabled`, `key_name_prefix`) with their present defaults,
including the legacy description; correct misleading descriptions without
changing behavior. Pass them to the KMS child without renaming the public API.

Validation contract:
- Integers in inclusive ranges: delay 0..900; visibility 0..43200; retention
  60..1209600; KMS reuse 60..86400; message size 1024..1048576; long polling
  0..20; key deletion 7..30. Every validation has an actionable `error_message`.
- JSON syntax for `policy`, `key_policy`, and both redrive policies; redrive
  requires a nonempty DLQ ARN and integer `maxReceiveCount` 1..1000.
  Allow-policy permission is `allowAll`, `denyAll`, or `byQueue`; `byQueue`
  requires 1..10 source ARNs, other modes must not supply source ARNs.
- Existing key-spec enumeration stays supported by the public input; when the
  key is actually used for SQS, preconditions require symmetric
  `SYMMETRIC_DEFAULT` and `ENCRYPT_DECRYPT`.
- Enum rules for deduplication/throughput and alias prefix `alias/`.
- Preconditions reject conflicting name/prefix, FIFO-only options on a standard
  queue, wrong FIFO suffix, incompatible throughput/deduplication combination,
  created plus existing key, and any non-null SQS-SSE setting alongside KMS.
  In KMS modes emit no `sqs_managed_sse_enabled` argument, even false, because
  the provider declares it conflicting with `kms_master_key_id`.
- `create_kms_key=false`, no external key, and SQS-SSE null delegates to the
  provider; explicit false permits caller-selected unencrypted operation.
  Do not silently change the default encryption selection.

### `outputs.tf`: SQS
Retain `arn: string` and `id: string` (queue URL). Add `name: string`,
`url: string`, `tags_all: map(string)`, `kms_key_arn: string?`, and
`kms_key_id: string?`. Key outputs identify the created child key; return null
when no child key exists rather than pretending an alias input is a resolved
ARN. Add `effective_kms_master_key_id: string?` for the exact key reference
passed to SQS, including externally supplied aliases.

### `main.tf`: SQS
- Keep `aws_sqs_queue.queue` unkeyed and uncounted.
- Replace inline cross-cutting KMS resources with `module.kms`, source
  `../kms`, counted only when `create_kms_key` is true.
- Retain permanent declarative moves:
  `aws_kms_key.sqs` to `module.kms[0].aws_kms_key.this`, and
  `aws_kms_alias.sqs` to `module.kms[0].aws_kms_alias.this`.
  Preserve alias prefix and existing key properties during the move.
- Declare identity, region, and partition data only where policy generation
  needs them; region overrides must also determine policy ARN construction.
  Avoid the old invalid `:queue/` SQS ARN form: SQS ARNs end in `:<queue-name>`.
  Do not reference the queue resource ARN from a key policy that the same
  queue depends on. Derive restrictions from known name/account/region inputs;
  for generated naming use a narrowly scoped prefix where available, with
  account-scoped delegation rather than a resource dependency cycle.
  Default key administration delegates to the account root; service-use
  permissions must be restricted to the actual queue/account, not broad
  wildcard action families. A policy correction may be an in-place update,
  never a replacement requirement.
- Forward all queue inputs and conditional timeout blocks. KMS reuse is omitted
  in non-KMS modes. Do not add a separate policy resource for inline redrive.
- Merge a Name tag with caller tags for queue and created key, with caller
  tags winning. Document the additive tag diff for legacy callers.
- No lifecycle ignores that hide encryption, redrive, name, or timing drift.

### `variables.tf`: Lambda event-source mapping
Keep required `function_name: string`; retain `event_source_arn: string` but
relax its requiredness to nullable default null for self-managed Kafka. Preserve
legacy `batch_size: string = "10"` and `enabled: string = "true"` signatures, with
explicit numeric/boolean normalization at the resource boundary. Preserve the
effective defaults 10 and true, including numeric/boolean caller values
convertible by HCL. Add:
- `function_response_types: set(string) = []`: empty or
  `["ReportBatchItemFailures"]`, never silently enabled or dropped.
- `maximum_batching_window_in_seconds: number?`: integer 0..300; null preserves
  the source/provider default, including 500ms defaults for Kafka/MQ/DocumentDB.

Retain `starting_position: string = ""` and
`starting_position_timestamp: string = ""`; normalize empty strings to omitted
values and wire nonempty values rather than retaining commented-out arguments.
Document that supplying previously ignored stream arguments is a behavior
repair and can require mapping replacement (not part of the required SQS move).
Single-input validation checks allowed response values, window range/integrality,
numeric batch syntax/integrality and global range 1..10000, boolean syntax,
position enum or empty, and
RFC3339 timestamp or empty. Resource preconditions enforce source-specific batch
limits, batching requirements, partial-response support, starting-position
requirements, and timestamp/position/source combinations. SQS never receives
starting-position arguments. FIFO SQS has maximum batch size 10 and standard
SQS maximum 10000; standard SQS batches above 10 require window at least 1.
Complete the provider surface with these nullable inputs (descriptions are
their provider configuration purpose):
- `event_source_arn` becomes nullable with default null to support self-managed
  Kafka; `function_name` remains required. Exactly one ARN/self-managed source
  is required by a resource precondition.
- `region: string?`, `bisect_batch_on_function_error: bool?`,
  `kms_key_arn: string?`, `maximum_record_age_in_seconds: number?`,
  `maximum_retry_attempts: number?`, `parallelization_factor: number?`,
  `tumbling_window_in_seconds: number?`, `tags: map(string) = {}`,
  `use_resource_timeout_for_propagation: bool = false`,
  `timeouts: object({create=optional(string),update=optional(string),
  delete=optional(string)})?`.
- `destination_config: object({on_failure=optional(object({
  destination_arn=string}))})?`.
- `document_db_event_source_config: object({database_name=string,
  collection_name=optional(string),full_document=optional(string,"Default")})?`.
- `filter_criteria: object({filter=optional(set(object({
  pattern=optional(string)})),[])})?`.
- `metrics_config: object({metrics=set(string)})?`.
- `provisioned_poller_config: object({minimum_pollers=optional(number),
  maximum_pollers=optional(number),poller_group_name=optional(string)})?`.
- `scaling_config: object({maximum_concurrency=optional(number)})?`;
  an empty object supports clearing this setting.
- `queues: list(string) = []`, `topics: set(string) = []`,
  `self_managed_event_source: object({endpoints=map(string)})?`,
  `source_access_configuration: set(object({type=string,uri=string})) = []`.
- `amazon_managed_kafka_event_source_config` and
  `self_managed_kafka_event_source_config`: each
  `object({consumer_group_id=optional(string),
  schema_registry_config=optional(object(Registry))})?`.
- Registry: `access_config: set(object({type=optional(string),
  uri=optional(string)}))? = []`, `event_record_format: string?`,
  `schema_registry_uri: string?`,
  `schema_validation_config: set(object({attribute=optional(string)}))? = []`.

Validate record age -1 or integer 60..604800; retries integer -1..10000;
parallelization integer 1..10; tumbling integer 0..900; concurrency integer >=2
without an arbitrary 1000 ceiling; poller minimum 1..200, maximum 1..2000 and
min<=max (SQS minimum is 2); group name length 1..128; Kafka consumer-group
length 1..200; one MQ queue with length 1..1000; one Kafka topic with length
1..249; at most 22 source access entries; at most 10 filters with JSON patterns
up to 4096 characters. Ten filters is the provider/raised-quota limit, not a
claim that every AWS account has a quota of ten. Source-access types are
BASIC_AUTH, VPC_SUBNET, VPC_SECURITY_GROUP, SASL_SCRAM_512_AUTH,
SASL_SCRAM_256_AUTH, VIRTUAL_HOST, CLIENT_CERTIFICATE_TLS_AUTH and
SERVER_ROOT_CA_CERTIFICATE; registry auth types are BASIC_AUTH,
CLIENT_CERTIFICATE_TLS_AUTH and SERVER_ROOT_CA_CERTIFICATE.
Record formats are JSON/SOURCE, schema attributes KEY/VALUE, DocumentDB
full-document modes Default/UpdateLookup and metrics
EventCount/ErrorCount/KafkaMetrics.

Source-aware preconditions reject ARN/self-managed conflicts, conflicting
managed/self-managed Kafka configuration, non-Kafka topics/registry settings,
non-MQ queues, non-SQS scaling, DocumentDB settings on another source, and
partial responses on MQ/DocumentDB. Support provider/AWS-documented Kafka
capabilities rather than denying them based only on stale provider prose.
SQS FIFO rejects a positive batching window. Kinesis/DynamoDB batches above
10 have conflicting historic/provider versus current AWS API documentation;
preserve historically accepted stream defaults, enforce the unambiguous SQS
rule, and document the service constraint rather than silently rejecting
existing stream configurations.

For Kafka/MQ/DocumentDB, setting an integer window loses the original 500ms
service default; returning to that default requires replacement. Provider
create behavior may omit explicit zero while updates send zero. Document this
API nuance; mock plans prove argument wiring, not live window transitions.

### `outputs.tf`: Lambda event-source mapping
Add `id: string`, `uuid: string` (same identifier), `arn: string`,
`function_arn: string`, `event_source_arn: string?`, `state: string`,
`state_transition_reason: string?`, `last_modified: string?`, and
`last_processing_result: string?`, `tags_all: map(string)`, `batch_size: number`,
`enabled: bool`, `function_response_types: set(string)`, and
`maximum_batching_window_in_seconds: number?`. Expose provider-computed metadata without
inventing live delivery guarantees from mocked tests.

### `main.tf`: Lambda event-source mapping
Retain `aws_lambda_event_source_mapping.this` without count/for_each, pass the
response set and nullable window unchanged, and conditionally emit optional
source-specific blocks. No lifecycle ignores or implicit new Lambda/IAM/SQS
resources. For mapping tags, merge Name=function_name with caller tags.
Caller map/YAML examples preserve the singleton leaf address under each module key.

### `variables.tf`: API Gateway v2
Preserve existing variable names, types and defaults unless explicitly relaxed
below. In particular preserve required `name: string`, `protocol_type: string`,
`api_key_selection_expression="$request.header.x-api-key"`,
`route_selection_expression="$request.method $request.path"`,
`disable_execute_api_endpoint=false`, `fail_on_warnings=false`,
`tags: map(string)={terraform="true"}`, nullable body/credentials/description/
route_key/target/api_version, and CORS defaults (object `{}`, credentials false,
max age 0). CORS is meaningfully configured only when credentials are true,
max_age is nonzero, or any allow/expose list is nonempty (null/[] count as
empty). A false/zero-only object is semantically empty, including the typed
default `{}` after optional defaults expand; omit its block. Reject meaningful
CORS with WebSocket or OpenAPI body instead of silently dropping it.
Add `region: string?` for all resources and `ip_address_type: string?` on the
API. Preserve provider defaults, including integration payload 1.0 and stage
auto-deploy false; issue examples explicitly override them.

All current resource collections remain `map(object(...)) = {}`, also accepting
explicit null as empty; reject null elements. Preserve every currently declared
field. Add the following concrete fields:
- `integrations`: `integration_subtype: string?`,
  `payload_format_version: string?`, `template_selection_expression: string?`,
  `response_parameters: map(object({mappings=map(string),
  status_code=string}))? = {}`,
  `tls_config: object({server_name_to_verify=optional(string)})?`,
  `vpc_link_key: string?` as an alternative to literal `connection_id`.
  Existing fields remain optional strings for connection ID/type, content
  handling, credentials, description, method/type/URI, passthrough; optional
  map(string) request parameters/templates; optional numeric timeout.
- `routes`: `request_parameter: map(object({request_parameter_key=string,
  required=bool}))? = {}`, `integration_key: string?`,
  `authorizer_key: string?`. Retain plural
  `request_parameters: map(string)?` as a deprecated boolean-string adapter:
  parameter-key => "true"/"false", converted to the provider block.
  Reject nonempty singular plus plural. Keep optional api_key_required bool,
  authorization_scopes list(string), request_models map(string), and string
  authorization_type, authorizer_id, model_selection_expression, operation_name,
  route_key, route_response_selection_expression and target. `route_key` must
  be supplied; do not silently substitute the map key.
- `stages`: retain auto_deploy bool, description string, stage_name string as
  optional fields. Add `access_log_settings: object({destination_arn=string,
  format=string})?`, `default_route_settings: object(RouteSettings)?`,
  `route_settings: map(object(RouteSettings))? = {}`,
  `client_certificate_id: string?`, `deployment_id: string?`,
  `stage_variables: map(string)?`, `tags: map(string)?`.
  RouteSettings contains optional data_trace_enabled/detailed_metrics_enabled
  bools, logging_level string, throttling_burst_limit/throttling_rate_limit
  numbers. Per-route keys are actual route keys. Wire stage description.
- `authorizers`: retain optional string authorizer_credentials_arn,
  authorizer_type, authorizer_uri, name, token_validation_expression;
  optional number authorizer_result_ttl; optional list(string) identity_sources,
  provider_arns and scopes. Add `authorizer_payload_format_version: string?`,
  `enable_simple_responses: bool?`,
  `authorizer_result_ttl_in_seconds: number?`,
  `jwt_configuration: object({audience=optional(list(string)),
  issuer=optional(string)})?`, and
  `timeouts: object({delete=optional(string)})?`.
  Canonical TTL takes the old TTL as fallback, including zero; unequal duplicate
  values fail. Meaningful top-level `jwt_configuration` remains a JWT-only
  fallback; if nested and global are both configured, require equal values.
  Never emit JWT configuration for REQUEST or an empty default global object.
- `domain_names`: retain required nested `domain_name_configuration` with
  required certificate_arn string, optional endpoint_type="REGIONAL",
  security_policy="TLS_1_2", ownership_verification_certificate_arn string.
  Add nested `ip_address_type: string?`, top-level `routing_mode: string?`,
  `mutual_tls_authentication: object({truststore_uri=string,
  truststore_version=optional(string)})?`,
  `timeouts: object({create=optional(string),update=optional(string)})?`.
  Global mTLS remains accepted as fallback; reject differing simultaneous
  global/per-domain configurations. Read the declared nested fields, not flat
  aliases that never survived input type conversion.
- `integration_responses`: retain required string integration_id and
  integration_response_key, optional content_handling_strategy string,
  response_templates map(string), template_selection_expression string.
  Relax integration_id to optional and add `integration_key: string?`;
  require exactly one literal ID or internal key.
- `models`: retain required string content_type, name and schema, optional
  description string. Preserve key-derived resource naming despite legacy name.
- `route_responses`: retain required string route_id/route_response_key,
  optional response_models map(string)/model_selection_expression string.
  Relax route_id to optional and add `route_key: string?` for the logical
  parent-map key; require exactly one ID or key.
- `vpc_links`: retain required list(string) security_group_ids/subnet_ids and
  optional map(string) tags; merge per-link tags instead of ignoring them.

Compatibility decisions: authorizer `name`, model `name`, and stage `stage_name`
remain deprecated no-op aliases; actual names stay map keys even when an alias
differs, preventing accidental replacement. Authorizer provider_arns, scopes
and token_validation_expression are retained deprecated no-ops because they
are not v2 provider fields; direct callers to routes.authorization_scopes or
the correct authentication system. No unsupported resource argument is invented.

Validation contract:
- Fix description length <=1024 and api_version length 1..64 with actual
  comparisons, not `can(boolean)`. Preserve null acceptance. Protocol is
  HTTP/WEBSOCKET; IP is ipv4/dualstack.
- Integration type must be present; enum AWS/AWS_PROXY/HTTP/HTTP_PROXY/MOCK,
  connection type INTERNET/VPC_LINK, content handling CONVERT_TO_BINARY/
  CONVERT_TO_TEXT, passthrough WHEN_NO_MATCH/WHEN_NO_TEMPLATES/NEVER,
  payload 1.0/2.0. Timeout is integer 50..30000 HTTP or 50..29000 WebSocket.
  Response status strings represent integers 200..599.
- Routes require route_key and valid NONE/AWS_IAM/CUSTOM/JWT authorization;
  deprecated parameter values must be exactly "true"/"false".
  Stage logging is ERROR/INFO/OFF, throttling nonnegative (burst integer),
  and nonempty access logs require destination and format. For HTTP do not
  emit WebSocket-only data tracing/logging-level settings.
- Authorizers require REQUEST/JWT, payload 1.0/2.0 if provided, TTL integer
  0..3600. HTTP REQUEST needs payload version; simple responses require 2.0;
  JWT needs meaningful audience/issuer. Validate TTL/JWT duplicate conflicts.
- Domain endpoint REGIONAL, TLS_1_2, IP ipv4/dualstack; routing mode
  API_MAPPING_ONLY/ROUTING_RULE_ONLY/ROUTING_RULE_THEN_API_MAPPING.
  Validate duplicate mTLS conflicts. Validate nonempty subnet/security-group
  collections and JSON model schemas.
- Within-map contradictions target the relevant map variable. Cross-input
  preconditions reject incompatible HTTP/WebSocket-only options, explicit
  resource management alongside conflicting OpenAPI body/CORS/version, and
  quick-create target ownership overlapping explicit integrations/routes/stages.
  Default empty CORS must not cause false conflicts.
- Internal key versus literal conflicts and unresolved references fail on the
  owning resource: target/integration_key, authorizer_id/authorizer_key,
  connection_id/vpc_link_key, response parent ID/key. Validate existence without
  changing keys. Use guarded lookups with null fallback so an invalid index
  cannot preempt the intended precondition diagnostic. Optional route target,
  authorizer and connection references allow neither value; response parent
  references require exactly one. Literal route targets must retain
  `integrations/<id>` format.

### `outputs.tf`: API Gateway v2
Preserve `id`, `api_endpoint`, `arn`, `execution_arn`,
`api_key_selection_expression`, `tags_all`, and the provider-shaped
`cors_configuration` output, not a newly reshaped object.
Add `integration_ids`, `route_ids`, `authorizer_ids`, `model_ids`,
`integration_response_ids`, `route_response_ids`, `vpc_link_ids`,
`vpc_link_arns`, `stage_ids`, `stage_invoke_urls`, `stage_execution_arns`,
`stage_arns`, and `integration_response_selection_expressions` as map(string),
keyed by the original resource map keys. Add `domains` as
map(object({id=string,arn=string,target_domain_name=string,hosted_zone_id=string,
api_mapping_selection_expression=string})), plus domain/stage/VPC-link tags_all
as map(map(string)). Unused collections return empty maps, not untyped objects.
Output block types are inferred; do not add unsupported `type` arguments.

### `main.tf`: API Gateway v2
Retain singleton `aws_apigatewayv2_api.this`; retain the exact keyed
`aws_apigatewayv2_authorizer.this`, `aws_apigatewayv2_domain_name.this`,
`aws_apigatewayv2_integration.this`, `aws_apigatewayv2_integration_response.this`,
`aws_apigatewayv2_model.this`, `aws_apigatewayv2_route.this`,
`aws_apigatewayv2_route_response.this`, `aws_apigatewayv2_stage.this`, and
`aws_apigatewayv2_vpc_link.this`. No deployment or API-mapping resources are
added implicitly. Wire canonical nested JWT/domain settings using the correct
dynamic-block iterator. Resolve optional internal keys to IDs with explicit
dependencies, including the `integrations/` route-target prefix.

Use conditional blocks for CORS, JWT, mTLS, response mappings, TLS, route
parameters, stage logging/settings, and supported timeouts. Apply common region
consistently to all resources. Merge Name plus shared tags and supported
per-entry tags on taggable resources; retain caller precedence. Keep resources
without tag support untagged. No drift-hiding lifecycle ignores. The API README
source must point to `//modules/aws/api_gateway/v2`, not the parent directory.

## 5. Breaking-change assessment
- Resource identity: no intentional recreation for the required consumer
  configurations. Keep all existing queue, mapping, API and keyed API child
  addresses. KMS addresses change only through permanent `moved` declarations.
- Public configuration: preserve existing defaults and input names. Accept
  existing numeric strings via conversion. Newly rejected malformed values,
  invalid protocol combinations, or previously ignored conflicting settings
  are documented repairs, not silent reinterpretations.
- Toolchain compatibility: **breaking for callers below the new language or
  provider floors**. API v2 currently advertises AWS >=4.0.0 and language >=1.0.0;
  corrected constraints must be explicit. Existing SQS/mapping floors also
  rise for newly exposed provider options. Under the repository's strict SemVer
  policy, ship these existing-module floor increases in a MAJOR release unless
  maintainers split the work to avoid a compatibility increase. The new
  DynamoDB module alone is additive. Do not label the combined release
  unconditionally non-breaking.
- Previously ignored stream starting-position arguments, API names, logging,
  and authorizer options may begin affecting remote behavior. Release notes
  must call these out and identify any ForceNew fields. Do not change an
  established keyed name implicitly merely because a previously ignored alias
  is present; compatibility rules below govern aliases.

### Adoption and address inventory
Documentation must include complete, copyable declarative `moved` examples in
the implementation READMEs (this specification lists address pairs only):
- Native `aws_dynamodb_table.webhook` to
  `module.tables.aws_dynamodb_table.this["webhook"]`.
- Native `aws_sqs_queue.work` to
  `module.queues["work"].aws_sqs_queue.queue`, and the corresponding `"dlq"`
  pair; module map keys must remain stable.
- Native `aws_lambda_event_source_mapping.work` to
  `module.mapping.aws_lambda_event_source_mapping.this`, plus the keyed caller
  module variant.
- Native API to `module.http.aws_apigatewayv2_api.this`; native integration,
  route, and stage to
  `module.http.aws_apigatewayv2_integration.this["webhook"]`,
  `module.http.aws_apigatewayv2_route.this["webhook"]`, and
  `module.http.aws_apigatewayv2_stage.this["$default"]`.

List every other keyed API resource address using its unchanged `.this[key]`
pattern, and both KMS moves above. Include import identifiers: table name,
queue URL, mapping UUID, API ID, and provider-documented composite IDs for API
children. A move applies to objects already in the same state; an import
adopts objects not in state. Do not propose importing an already managed object
twice. Adoption examples must preserve stable names, billing/key schemas,
queue type, encryption, retention/visibility, integration URI/method/payload,
authorization, and logging. No `ignore_changes` concealment or
destroy/recreate procedure is acceptable.

Default KMS callers must first adopt the refactor with key creation unchanged.
Switching a previously KMS-encrypted queue to SQS encryption and disposing of
its old key are separate, explicit consumer decisions, not part of an
address-only migration. Already SQS-encrypted native queues adopt with
`create_kms_key=false` and `sqs_managed_sse_enabled=true` from the outset.
Consumers pin the eventual released tag/commit, inspect a real plan against
their own state, and require no unintended destroys/replacements. Offline
module tests do not certify any particular production state.

## 6. Checkov / tfsec considerations
- New suppressions: none pre-authorized. Keep encryption enabled in baseline
  examples, PITR/deletion protection enabled on new tables, and access logging
  enabled in the HTTP adoption example. Do not introduce a global suppression
  merely to make scanning green.
- Existing suppressions affected: API `CKV_AWS_309` (caller-controlled route
  authorization) and `CKV2_AWS_4` (stage logging settings) remain applicable;
  do not remove or broaden them. Existing caller-controlled encryption policy
  remains unchanged.
- AWS-managed/SQS-owned encryption is valid for this feature. If scanners
  require CMKs despite encryption being enabled, document the exact finding
  and narrow caller-configurability rationale for review; do not redesign the
  feature or force a key to satisfy a scanner.
- The HTTP example's access-log format may contain request ID, status, response
  length and latency, but not path, raw path, route key containing the token,
  request body, headers, or authorization data. Application token validation
  remains mandatory in the application; API authorization may explicitly be
  `NONE`. Do not claim the module implements application authentication.
- Any justified future inline tfsec suppression must use the repository's
  `#tfsec:ignore:<check>` convention and an adjacent rationale.

## 7. terraform-docs impact
The generated `<!-- BEGIN_TF_DOCS -->` blocks change in all four affected
READMEs: new DynamoDB interface, SQS encryption/redrive and additional provider
options, mapping configuration/outputs, and API v2 corrected nested types and
new output maps. Regenerate each with
`terraform-docs markdown table --output-file README.md --output-mode inject <path>`.
CI verifies committed output and never supplies missing generated docs.

Each README must have description, prerequisites, complete module usage,
design notes, minimum versions, import/move addresses, and release-pin guidance.
Include the exact issue examples, a multi-resource map/YAML example, legacy
encryption regression notes, and a safe HTTP log format. Logging destination,
Lambda execution permissions, Lambda invocation permissions, certificates,
and external keys are caller prerequisites, not hidden resources.

## 8. Testing
### Execution and fixture rules
For each of the four module paths, implementation runs
`tofu -chdir=<path> init -backend=false`,
`tofu -chdir=<path> validate`, and `tofu -chdir=<path> test`.
Run `tofu fmt -check -diff -recursive`, per-module terraform-docs regeneration
followed by a no-diff check, repository Unicode checking, and
`checkov -d <path>` using the repository configuration. Record findings and
their dispositions. Use the repository pre-commit hooks if installed.
Also validate with the declared minimum provider versions and an available
current release; test Terraform compatibility without post-fork-only syntax.

All native cases use `mock_provider "aws"` and deterministic `mock_resource` /
`mock_data` defaults, modeled on `modules/aws/organizations/tests/`. Provider
installation may access registries; plans/tests must never access AWS,
credentials, a real backend, or live state. Use plan runs for configurable
behavior and mocked apply runs only where computed output equality needs them.
Mock computed IDs/ARNs, never the input values or parent/child wiring under test.

Each validation predicate below requires its own named `run` with
`expect_failures=[var.<owning-input>]`; compound rules require one run per
distinct failure. Cross-input resource preconditions instead use
`expect_failures=[<resource-address>]`. Type errors are not falsely described
as variable-validation failures. Add one negative run for every additional
validation introduced during implementation. Never delete, skip, narrow, or
mock away a failing behavior to pass the suite.

### DynamoDB: `tests/table.tftest.hcl`, `validation.tftest.hcl`
- Valid required table asserts PAY_PER_REQUEST, physical name, `pk` type S,
  enabled TTL on `ttl`, PITR and AWS-managed SSE with null customer key.
  Assert secure defaults including deletion protection and absence of a key
  resource. TTL must not be included as an unused attribute definition.
- Empty/two-table maps; shared/per-table Name overrides; provisioned table/GSI;
  legacy versus ordered GSI schemas; ALL/KEYS_ONLY/INCLUDE; LSI; streams on/off;
  SSE modes; TTL absent/enabled/disabled-with-name; PITR disable/retention;
  on-demand caps including -1; warm capacity; EVENTUAL/STRONG replica/witness
  cardinalities; CSV import options versus JSON/ION; all three restore sources;
  timeout and explicit-region versus provider-region branches.
- For each var.tables rule, separate negative runs: invalid enums; fractional/
  out-of-range numbers; missing provisioned units; billing/capacity/cap
  conflicts; duplicate/unused/missing attributes; bad/duplicate index names;
  invalid ordered-key counts/types/conflicts; missing TTL name; projection
  mismatch; LSI without base sort key; stream/view mismatch; every import/
  restore-source conflict; contradictory date/latest, invalid timestamp;
  CSV options on another format; duplicate/mixed replica regions/consistency;
  witness/cardinality errors; STRONG TTL/LSI. Add valid boundary companions.
- Assert exact keyed names, IDs, ARNs, stream values/nulls, replica nesting,
  tags_all and aggregate tables output, not just cardinality/non-nullness.

### SQS: `tests/queue.tftest.hcl`, `validation.tftest.hcl`, `wiring.tftest.hcl`
- Baseline legacy defaults create one queue and exactly one child key/alias;
  assert queue key reference equals the child's mocked ARN and every legacy
  `key_*` setting reaches the real child resource, including policy and region.
- SQS-owned work queue: no KMS module/key/alias, standard queue, exact visibility
  720, decoded redrive DLQ ARN and configurable integer receive count.
  DLQ: no key/alias, retention exactly 1209600; exercise allow-policy absent,
  allowAll, denyAll, and byQueue.
- Separate existing-key cases for ARN, key ID and alias: no created key,
  exact queue reference, null created-key outputs. Exercise explicit
  encryption disable and provider-default delegation without changing legacy
  defaults. Each optional policy/timeout/naming/region branch gets null/set
  coverage; standard and FIFO configurations both plan.
- For every numeric range, separate lower-than-minimum, above-maximum and
  fractional cases, plus valid inclusive endpoints. Include 720 visibility,
  1209600 retention, `"720"` compatibility and the 1MiB message-size boundary.
- Separate failures for malformed JSON in each policy input; missing/empty
  DLQ ARN; missing, string-valued, fractional, zero and >1000 receive counts;
  invalid redrive permission; missing, empty or >10 byQueue sources; sources
  supplied to allowAll/denyAll; invalid enums, alias prefix and key spec.
- Preconditions separately reject all encryption conflicts, both naming
  arguments, FIFO suffix errors/options on standard queues, incompatible
  high-throughput settings, asymmetric key, and wrong key usage.
- Assert exact `arn`, `id`, `url`, `name`, `tags_all`, created-key identifiers,
  and effective key reference, including null cases and caller Name override.
- A dedicated migration harness with synthetic state must retain the same
  root/state across the legacy-to-production configuration transition and
  inspect planned actions for both real KMS moved declarations and unchanged
  queue address. Ordinary isolated native runs with fresh state cannot prove
  this transition. Keep AWS interactions mocked; exercise the production
  child, not an overridden module. Structural address assertions alone must
  not be reported as a state-transition or production migration test.

### Mapping: `tests/mapping.tftest.hcl`, `validation.tftest.hcl`
- Valid legacy SQS baseline retains batch 10, enabled true, empty response
  set and omitted window; required case asserts batch 10, window 5 and exactly
  `ReportBatchItemFailures`, enabled true and unchanged source/function.
- Enabled false, empty/set responses, null/zero/nonzero windows, and each
  optional source block present/absent. Cover standard/FIFO SQS, DynamoDB,
  Kinesis, Kafka, MQ and DocumentDB where exposed by the full provider surface.
- Separate validation failures for unsupported response value, window -1,
  301 and fraction; malformed/fractional/out-of-range batches; invalid boolean
  string; invalid starting position and timestamp.
- Source precondition failures: FIFO batch >10, standard SQS >10000,
  standard batch >10 without window >=1, partial response on unsupported source,
  SQS stream-position arguments, stream missing required position,
  timestamp without AT_TIMESTAMP, AT_TIMESTAMP without timestamp, and
  AT_TIMESTAMP on DynamoDB. Include passing stream position/timestamp cases.
- FIFO positive window; exactly-one source and managed/self-managed conflicts;
  wrong-source optional blocks; all record-age/retry/parallelization/tumbling/
  concurrency/poller bounds, integrality and ordering; source-access/registry/
  metrics enums; queue/topic/group length and cardinality; filter JSON/length/
  count, including acceptance of six through ten filters under raised quota.
  Every failure maps to its own input validation or resource precondition.
- Assert each output equals the corresponding deterministic provider attribute;
  `id == uuid` exactly. Do not settle for non-null metadata assertions.

### API v2: `tests/http.tftest.hcl`, `optional_paths.tftest.hcl`, `validation.tftest.hcl`
- Required HTTP baseline has exactly one API, Lambda AWS_PROXY integration
  using POST and payload 2.0, route `POST /webhook/{token}` with `NONE`
  authorization, and auto-deployed `$default` stage. Assert an external log
  destination and the exact safe format, without path/token-bearing fields.
- Minimal objects must plan with every optional block omitted. Exercise each
  resource map empty/null and populated, multiple stable keys, CORS omitted
  and set, and OpenAPI import versus explicit-resource paths.
- Exercise integration subtype, templates, request/response mappings and TLS;
  route singular/plural parameters; stage default/per-route metrics, throttling
  and logging; REQUEST versus JWT authorizers and global/per-authorizer JWT;
  nested domains and mTLS; integration responses, models, route responses and
  VPC links. Assert meaningful supplied values reach real resource arguments.
- Separate `expect_failures` cases for every planned map validation and every
  distinct compatibility conflict below, with positive boundary cases.
  Cross-map reference failures target owning resource preconditions.
- Specifically cover description 1025, API version empty/65, invalid enum for
  every declared field, missing required integration type/route key/JWT config,
  timeout below/above bounds and fractional, response status out of range,
  TTL -1/3601/fraction, simple responses with payload 1.0, plural-parameter
  invalid boolean, singular/plural conflict, duplicate TTL/JWT/mTLS conflicts,
  invalid model JSON, empty VPC-link collections, null map elements, and
  unknown or simultaneously literal/key references. Assert differing legacy
  name aliases do not rename resources; TTL zero is forwarded exactly.
- Assert exact API ID/ARN/endpoint/execution ARN and preserved existing outputs;
  new keyed ID, ARN, invoke URL and domain outputs must retain exact caller
  keys and computed fixture values, with empty maps when unused.
- Wiring fixtures pass mocked integration/authorizer IDs through internal key
  references to routes, route IDs to responses, and VPC-link IDs to
  integrations; assert exact values, not only resource counts.
- Optional references with neither literal nor key must also plan; each
  key/literal conflict and unknown key fails on the intended resource
  precondition, not an indexing error. Response-parent references require one
  value. Prove route-response logical route keys are not confused with
  actual HTTP route strings. False/zero-only CORS omits the block while
  meaningful CORS conflicts fail explicitly.

### Cross-workstream adoption fixture
Add an offline native fixture under an affected module's `tests/fixtures/`
composing the real four modules. It must prove DLQ ARN feeds work redrive,
work queue ARN feeds the mapping, and API execution ARN/endpoint plus keyed
integration/route/stage outputs are available without duplicate resources.
Supply fake external Lambda/log-group identifiers. Verify eight application
resources and zero KMS resources for the required configuration. Separately
exercise migration address pairs using synthetic state, including keyed
instances, and require no replacement/destruction for address-only adoption.
State fixtures are generated test artifacts and must contain no live data.

## 9. Open questions
- None blocking: choose the new table submodule path
  `modules/aws/dynamodb/table/`; retain singleton leaf addresses for existing
  queue/mapping modules; use explicit caller map/YAML composition.
- Release ordering is a maintainer decision, not an implementation ambiguity:
  four independent implementation changes are allowed, but #537 remains open
  until all acceptance criteria pass. Constraint increases require the release
  assessment in section 5, even if the resource configurations are compatible.

## 10. Acceptance criteria
1. New keyed DynamoDB table module plans the exact issue configuration:
   stable name, PAY_PER_REQUEST, string partition key `pk`, enabled TTL on
   `ttl`, PITR and encryption without a customer-managed key; secure new
   defaults and complete provider input/output coverage are documented/tested.
2. Work/DLQ queue plans use SQS-owned encryption with no keys/aliases, preserve
   names and ARN/URL outputs, visibility 720 and DLQ retention 1209600, and
   configurable integer receive-count redrive plus optional allow policy.
3. Legacy queue key creation/defaults and existing-key mode have exact wiring
   regression coverage; repaired data sources and numeric validations work.
4. Mapping plans preserve batch 10, window 5, enabled control and exactly
   `ReportBatchItemFailures`, with meaningful UUID/metadata outputs.
5. All API v2 schemas agree with accessed provider arguments; HTTP Lambda
   AWS_PROXY POST/payload 2.0, the token route, and logged auto-deployed
   `$default` stage validate/plan without requiring an IAM/JWT authorizer.
6. All optional API paths, aliases, references and invalid combinations have
   substantive offline regressions; logging examples exclude token-bearing data.
7. Native suites cover baseline, every validation failure, all conditional
   branches, exact outputs and composition wiring without live credentials.
   Formatting, validation, docs generation, Unicode and security checks have
   recorded results; no assertion is weakened to hide a defect.
8. All four READMEs include complete usage and map/YAML examples, generated
   input/output documentation, prerequisites, design decisions, and minimum
   provider/tool versions justified by actual feature introduction.
9. Resource address inventory, native-to-module declarative move/import
   guidance including keyed instances, and synthetic migration tests establish
   non-destructive address-only adoption. Consumer state review follows release.
10. Release notes distinguish additive capabilities, schema/validation repairs,
    toolchain compatibility increases and intentional encryption changes.
    Consumers can pin a released tag/commit; this spec PR does not close #537.
