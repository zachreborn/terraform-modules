# Spec: VPC - Add CloudWatch Internet Monitor
**Issue:** #72
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The `modules/aws/vpc` module has no built-in observability for internet
connectivity issues affecting end users. Amazon CloudWatch Internet Monitor
uses AWS's internal connectivity probes to surface performance (RTT) and
availability health events for traffic flowing through a VPC, scoped to the
city-networks (client location + ASN) that actually reach your resources,
with no application code changes.
This spec adds a CloudWatch Internet Monitor to the VPC module via the
`aws_internetmonitor_monitor` resource. The feature is gated behind a single
`enable_internet_monitor` toggle (default `false`) so it is fully opt-in. The
VPC ARN (`aws_vpc.vpc.arn`, already exported as the `vpc_arn` output at
`modules/aws/vpc/outputs.tf:94`) is passed as the monitored resource ARN.
See: https://github.com/zachreborn/terraform-modules/issues/72

## 2. Non-goals
- Creating the S3 bucket used for internet-measurement log delivery. Per
  AGENTS.md §2 (no inline cross-cutting resources), the caller supplies an
  existing bucket name; this module only wires the delivery configuration.
- Creating CloudWatch alarms, dashboards, EventBridge rules, or SNS
  subscriptions on the monitor's metrics/health events.
- Monitoring non-VPC resources (NLBs, CloudFront distributions, WorkSpaces
  directories). Only the module's own VPC ARN is monitored.
- Cross-account monitoring (`include_linked_accounts` / `linked_account_id`)
  and the local-health-event sub-blocks
  (`availability_local_health_events_config` /
  `performance_local_health_events_config`). See §9.
- Supporting more than one monitor per module instance. The VPC module
  manages a single VPC, so a single monitor is sufficient and a map/`for_each`
  input (AGENTS.md §5) is not required.
- Any change to existing VPC variables, outputs, or resources.

## 3. Affected module path(s)
- `modules/aws/vpc/` (existing)

## 4. Proposed design
**Signatures only — no full implementations.**

### `variables.tf`
Add a new `# CloudWatch Internet Monitor` section (matching the module's
`###########################` header style) with the following variables:
- `enable_internet_monitor` — `bool`, default `false`. Whether to create a
  CloudWatch Internet Monitor for this VPC.
- `internet_monitor_monitor_name` — `string`, default `null`. Name of the
  Internet Monitor. Required when `enable_internet_monitor = true` (maps to
  `monitor_name`).
- `internet_monitor_traffic_percentage_to_monitor` — `number`, default `100`.
  Percentage of internet-facing traffic to monitor (1–100). Controls cost.
- `internet_monitor_max_city_networks_to_monitor` — `number`, default `100`.
  Maximum city-networks (location + ASN pairs) to monitor; hard billing cap
  (1–500000).
- `internet_monitor_status` — `string`, default `"ACTIVE"`. Monitor status.
  Valid values: `ACTIVE`, `INACTIVE`.
- `internet_monitor_availability_score_threshold` — `number`, default `95`.
  Health-event trigger threshold for availability score (%).
- `internet_monitor_performance_score_threshold` — `number`, default `95`.
  Health-event trigger threshold for performance score (%).
- `internet_monitor_s3_bucket_name` — `string`, default `null`. Optional S3
  bucket name for publishing internet measurements beyond the top-500
  city-networks.
- `internet_monitor_s3_bucket_prefix` — `string`, default `null`. Optional S3
  key prefix for internet-measurements delivery.
- `internet_monitor_s3_bucket_status` — `string`, default `"DISABLED"`.
  Enables (`ENABLED`) or disables (`DISABLED`) S3 measurement delivery.
  (See §9 — the issue lists `"INACTIVE"`, which is not a valid provider value
  for `log_delivery_status`.)
Recommended `validation` blocks (consistent with existing validated variables
such as `instance_tenancy` and `flow_traffic_type`):
- `internet_monitor_status` ∈ {`ACTIVE`, `INACTIVE`}.
- `internet_monitor_s3_bucket_status` ∈ {`ENABLED`, `DISABLED`}.
- `internet_monitor_traffic_percentage_to_monitor` in 1–100.
- `internet_monitor_max_city_networks_to_monitor` in 1–500000.
- `internet_monitor_availability_score_threshold` /
  `internet_monitor_performance_score_threshold` in 1–100.

### `outputs.tf`
Add two outputs that tolerate the disabled state (the resource uses `count`,
so use `one(...)` or `try(..., null)`):
- `internet_monitor_arn` — ARN of the Internet Monitor resource
  (`aws_internetmonitor_monitor.this[*].arn` via `one()`).
- `internet_monitor_id` — ID (name) of the Internet Monitor resource
  (`aws_internetmonitor_monitor.this[*].id` via `one()`).
Existing outputs are unchanged.

### `main.tf`
Add a new `# CloudWatch Internet Monitor` section containing one resource:
- `aws_internetmonitor_monitor` `"this"` with
  `count = var.enable_internet_monitor ? 1 : 0`. Argument mapping (full
  provider coverage):
  - `monitor_name = var.internet_monitor_monitor_name`
  - `resources = [aws_vpc.vpc.arn]` (the monitored VPC ARN)
  - `status = var.internet_monitor_status`
  - `traffic_percentage_to_monitor = var.internet_monitor_traffic_percentage_to_monitor`
  - `max_city_networks_to_monitor = var.internet_monitor_max_city_networks_to_monitor`
  - `tags = merge(tomap({ Name = var.name }), var.tags)` (repo tagging
    convention)
  - a static `health_events_config` block wired to
    `internet_monitor_availability_score_threshold` and
    `internet_monitor_performance_score_threshold`
  - a `dynamic "internet_measurements_log_delivery"` block (with a nested
    `s3_config`) emitted only when `var.internet_monitor_s3_bucket_name != null`,
    wiring `bucket_name`, `bucket_prefix`, and
    `log_delivery_status = var.internet_monitor_s3_bucket_status`
No new data sources, locals, lifecycle ignores, or `for_each` patterns are
required. The `required_providers` block already pins `aws >= 6.0.0`
(`modules/aws/vpc/main.tf:3-8`), which includes the
`aws_internetmonitor_monitor` resource — no version bump needed.

## 5. Breaking-change assessment
- Breaking: **no**.
- `enable_internet_monitor` defaults to `false`, so no new resources are
  created for existing callers.
- No existing variables, outputs, or resources are modified or removed; all
  new variables are additive with safe defaults.
- Callers who do not set `enable_internet_monitor = true` will see a zero plan
  diff.

## 6. Checkov / tfsec considerations
- New suppressions: **none**. The `aws_internetmonitor_monitor` resource is an
  observability resource that does not expose network-exposure or
  unencrypted-storage surfaces that the repo's scanners flag, and S3 delivery
  targets a caller-supplied bucket (whose own controls live with that bucket).
- Existing suppressions affected: **none**.

## 7. terraform-docs impact
**Yes** — the `<!-- BEGIN_TF_DOCS -->` block in `modules/aws/vpc/README.md`
will change and must be regenerated:
- Inputs table gains the ten new `internet_monitor_*` / `enable_internet_monitor`
  variables.
- Outputs table gains `internet_monitor_arn` and `internet_monitor_id`.
Regenerate locally via `pre-commit run --all-files` (or per-module
`terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/vpc`)
and commit the result — CI verifies but does not auto-commit. A usage example
enabling Internet Monitor should also be added to the README body outside the
generated block.

## 8. Testing
- `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc validate`
  (Terraform equivalents are also acceptable.)
- `tofu fmt -check -diff -recursive`
- `checkov -d modules/aws/vpc` (locally; CI runs on schedule)
- Manual plan checks:
  - Default (`enable_internet_monitor` unset) → no monitor resource, zero diff
    for existing callers.
  - `enable_internet_monitor = true` with a `internet_monitor_monitor_name` →
    monitor created against `aws_vpc.vpc.arn` with the threshold block.
  - `internet_monitor_s3_bucket_name` set → the
    `internet_measurements_log_delivery.s3_config` block is emitted; unset →
    the block is omitted.

## 9. Open questions
- **`internet_monitor_s3_bucket_status` default:** the issue lists a default of
  `"INACTIVE"`, but the provider's `log_delivery_status` only accepts
  `ENABLED` / `DISABLED`. This spec proposes `"DISABLED"` as the default and a
  validation restricting the value to that set. Confirm before implementation.
- **`monitor_name` required-when-enabled enforcement:** `required_version =
  ">= 1.0.0"` predates cross-variable `validation` (OpenTofu 1.8 /
  Terraform 1.9), so the "required when `enable_internet_monitor = true`"
  contract cannot be enforced with a cross-variable validation. Options:
  document it only, or add a `lifecycle { precondition { ... } }` on the
  resource. Decide which.
- **Local health-event sub-blocks:** AGENTS.md §1 (complete resource coverage)
  favors exposing every provider argument. This spec intentionally scopes out
  `availability_local_health_events_config` /
  `performance_local_health_events_config` (and `include_linked_accounts` /
  `linked_account_id`) to match the issue. Confirm whether these should be
  added now or tracked as a follow-up.

## 10. Acceptance criteria
- [ ] New variables added to `variables.tf` with correct types and defaults
      (feature disabled by default).
- [ ] `aws_internetmonitor_monitor` resource added to `main.tf` using
      `count = var.enable_internet_monitor ? 1 : 0`.
- [ ] VPC ARN (`aws_vpc.vpc.arn`) passed as the monitored resource ARN.
- [ ] `health_events_config` block wired to the threshold variables.
- [ ] Optional `internet_measurements_log_delivery` S3 block created when
      `internet_monitor_s3_bucket_name` is set.
- [ ] Outputs `internet_monitor_arn` and `internet_monitor_id` exported (using
      `one()`/`try()` so they resolve to `null` when disabled).
- [ ] `tofu fmt -recursive` passes with no diff.
- [ ] `tofu -chdir=modules/aws/vpc init -backend=false && tofu -chdir=modules/aws/vpc validate`
      passes.
- [ ] README regenerated via
      `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/vpc`.
- [ ] No existing callers produce a plan diff (backwards compatible).
