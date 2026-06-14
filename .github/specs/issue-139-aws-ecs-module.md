# Spec: Module - AWS ECS
**Issue:** #139
**Status:** Draft — pending CODEOWNERS review
**Owners:** @zachreborn @Jakeasaurus
**Type:** Feature

## 1. Background
The library ships `modules/aws/ecr/` (image registry) but has **no way to run
containers**. Callers who want Amazon ECS today must hand-write the cluster,
task/execution IAM roles, networking, logging, and service-discovery wiring,
which is inconsistent, not reusable, and does not inherit the library's
secure-by-default posture.
This spec introduces a new, purely additive `modules/aws/ecs/` module family —
one focused submodule per ECS resource type — so a caller can compose
`namespace` + `cluster` + `task_definition` + `service` using only `module {}`
blocks and get Well-Architected, CIS-aligned defaults out of the box. It follows
the established submodule pattern used by `modules/aws/iam/*`,
`modules/aws/route53/*`, and `modules/aws/s3/*`.
Cross-cutting concerns are satisfied by **composition** with existing modules
rather than inline resources, per `AGENTS.md` §2: task/execution roles via
`modules/aws/iam/role`, encryption keys via `modules/aws/kms`, log groups via
`modules/aws/cloudwatch/log_group`, and service security groups via
`modules/aws/security_group`.
"Namespaces" in ECS are **AWS Cloud Map** resources, not a native
`aws_ecs_namespace`; the `namespace` submodule manages
`aws_service_discovery_http_namespace` for ECS Service Connect, which the cluster
references via `service_connect_defaults` and services reference via
`service_connect_configuration`.
Originating issue: #139. Triage classified this as a feature with no
breaking-change risk.

## 2. Non-goals
- Does not modify any existing module. `modules/aws/iam/role`,
  `modules/aws/kms`, `modules/aws/cloudwatch/log_group`, and
  `modules/aws/security_group` are referenced via composition only, never
  changed.
- Does not create `global/` caller code that consumes these modules.
- Does not manage Application/Network Load Balancers or target groups; callers
  supply target-group ARNs from the existing `modules/aws/alb` /
  `modules/aws/lb` modules.
- Does not manage the EC2 Auto Scaling Group behind an EC2 capacity provider;
  the caller supplies an existing ASG ARN (Fargate / Fargate Spot need no
  capacity-provider resource at all).
- Does not manage container images or ECR repositories (already covered by
  `modules/aws/ecr`).
- Does not manage application autoscaling (`aws_appautoscaling_target` /
  `aws_appautoscaling_policy`) for services in this iteration — see Open
  questions.
- Does not manage DNS-based service discovery
  (`aws_service_discovery_private_dns_namespace` / `aws_service_discovery_service`)
  in this iteration; only the HTTP namespace used by Service Connect — see Open
  questions.
- Does not author container definitions; `container_definitions` is a
  caller-supplied JSON document.

## 3. Affected module path(s)
All new; nothing existing changes:
- `modules/aws/ecs/cluster/` (new) — `aws_ecs_cluster` (+ `aws_ecs_cluster_capacity_providers`).
- `modules/aws/ecs/capacity_provider/` (new) — `aws_ecs_capacity_provider` (EC2 Auto Scaling-backed).
- `modules/aws/ecs/task_definition/` (new) — `aws_ecs_task_definition`.
- `modules/aws/ecs/service/` (new) — `aws_ecs_service`.
- `modules/aws/ecs/namespace/` (new) — `aws_service_discovery_http_namespace` (Cloud Map namespace for Service Connect).

Referenced via composition only (not modified):
- `modules/aws/iam/role`, `modules/aws/kms`, `modules/aws/cloudwatch/log_group`, `modules/aws/security_group`.

Each submodule contains `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`,
started from `modules/module_template/`, with the standard `terraform {}` block
(`required_version = ">= 1.0.0"`, `aws >= 6.0.0`) and the repo tagging pattern
`tags = merge(tomap({ Name = var.name }), var.tags)`.

## 4. Proposed design
**Signatures only — no full implementations.** Names mirror the underlying
`hashicorp/aws` (`aws >= 6.0.0`) resource arguments so coverage stays complete
(`AGENTS.md` §1). Optional advanced arguments default to `null` so the provider
applies its own default unless the caller overrides.

### `modules/aws/ecs/cluster`
#### `variables.tf`
- `name` — `string` — Cluster name and tag `Name` value.
- `container_insights` — `string`, default `"enabled"` — Value for the `containerInsights` setting (`enabled` / `enhanced` / `disabled`).
- `additional_settings` — `list(object({ name = string, value = string }))`, default `[]` — Any other `setting` blocks.
- `service_connect_namespace_arn` — `string`, default `null` — Cloud Map namespace ARN for `service_connect_defaults`.
- `capacity_providers` — `list(string)`, default `["FARGATE", "FARGATE_SPOT"]` — Providers associated via `aws_ecs_cluster_capacity_providers`.
- `default_capacity_provider_strategy` — `list(object({ capacity_provider = string, base = optional(number), weight = optional(number) }))`, default Fargate-weighted strategy.
- Execute-command logging (encrypted by default; composes `kms` + `cloudwatch/log_group`):
  - `enable_execute_command_logging` — `bool`, default `true`.
  - `execute_command_logging` — `string`, default `"OVERRIDE"` — `NONE` / `DEFAULT` / `OVERRIDE`.
  - `create_kms_key` — `bool`, default `true` — Create a CMK via `modules/aws/kms` for exec-command + managed-storage encryption.
  - `kms_key_arn` — `string`, default `null` — Bring-your-own CMK; used when `create_kms_key = false`.
  - `create_cloud_watch_log_group` — `bool`, default `true` — Create the exec-command log group via `modules/aws/cloudwatch/log_group`.
  - `cloud_watch_log_group_name` — `string`, default `null` — Existing log group name when not creating one.
  - `cloud_watch_encryption_enabled` — `bool`, default `true`.
  - `log_group_retention_in_days` — `number`, default `365`.
  - `s3_bucket_name` — `string`, default `null`; `s3_key_prefix` — `string`, default `null`; `s3_bucket_encryption_enabled` — `bool`, default `true`.
- `managed_storage_kms_key_arn` — `string`, default `null` — Fargate ephemeral-storage CMK; defaults to the created CMK when `create_kms_key = true`.
- `tags` — `map(string)`, default `{}`.

#### `outputs.tf`
- `id`, `arn`, `name` — cluster identifiers.
- `kms_key_arn` — CMK ARN when created.
- `cloud_watch_log_group_name`, `cloud_watch_log_group_arn` — exec-command log group when created.

#### `main.tf`
- `aws_ecs_cluster.this` — `setting` block(s) from `container_insights` + `additional_settings`; `configuration.execute_command_configuration` (KMS key + `log_configuration`) when logging enabled; `configuration.managed_storage_configuration`; `service_connect_defaults.namespace` when an ARN is supplied.
- `aws_ecs_cluster_capacity_providers.this` — `capacity_providers` + `default_capacity_provider_strategy` (standalone resource, **not** deprecated in-line cluster args).
- `module "kms"` (`modules/aws/kms`) — `count`/conditional on `create_kms_key`.
- `module "log_group"` (`modules/aws/cloudwatch/log_group`) — conditional on `create_cloud_watch_log_group`.
- Standalone by design (one cluster per block); callers run several via separate blocks or `for_each` on the module.

### `modules/aws/ecs/capacity_provider`
#### `variables.tf`
- `name` — `string` — Capacity provider name.
- `auto_scaling_group_arn` — `string` — ARN of the existing ASG to back the provider.
- `managed_draining` — `string`, default `"ENABLED"`.
- `managed_termination_protection` — `string`, default `"ENABLED"`.
- `managed_scaling` — `object({ status = optional(string, "ENABLED"), target_capacity = optional(number, 100), minimum_scaling_step_size = optional(number), maximum_scaling_step_size = optional(number), instance_warmup_period = optional(number) })`, default enabled at 100% target.
- `tags` — `map(string)`, default `{}`.

#### `outputs.tf`
- `id`, `name`, `arn`.

#### `main.tf`
- `aws_ecs_capacity_provider.this` — `auto_scaling_group_provider` block with nested `managed_scaling`. Standalone by design (one provider per ASG); EC2-only (Fargate / Fargate Spot are referenced by name in the cluster and need no resource).

### `modules/aws/ecs/task_definition`
#### `variables.tf`
- `family` — `string` — Task definition family.
- `container_definitions` — `string` (JSON) — Caller-supplied container definitions document.
- `cpu` — `string`, default `null`; `memory` — `string`, default `null`.
- `network_mode` — `string`, default `"awsvpc"`.
- `requires_compatibilities` — `list(string)`, default `["FARGATE"]`.
- `runtime_platform` — `object({ operating_system_family = optional(string), cpu_architecture = optional(string) })`, default `null`.
- `ephemeral_storage_size_in_gib` — `number`, default `null`.
- `volumes` — `list(object({ ... }))`, default `[]` — `name` plus optional `host_path`, `configure_at_launch`, `docker_volume_configuration`, `efs_volume_configuration` (transit encryption on by default), `fsx_windows_file_server_volume_configuration`.
- `placement_constraints` — `list(object({ type = string, expression = optional(string) }))`, default `[]`.
- `proxy_configuration` — `object({ type = optional(string), container_name = string, properties = optional(map(string)) })`, default `null`.
- `ipc_mode` — `string`, default `null`; `pid_mode` — `string`, default `null`.
- `skip_destroy` — `bool`, default `false`; `track_latest` — `bool`, default `null`.
- Execution / task roles (composes `modules/aws/iam/role`; least-privilege, separate roles by default):
  - `create_execution_role` — `bool`, default `true`; `execution_role_arn` — `string`, default `null` (used when not creating).
  - `execution_role_managed_policy_arns` — `list(string)`, default includes `AmazonECSTaskExecutionRolePolicy`.
  - `create_task_role` — `bool`, default `true`; `task_role_arn` — `string`, default `null`.
  - `task_role_policy_json` — `string`, default `null` — Optional least-privilege inline policy for the task role.
- `tags` — `map(string)`, default `{}`.

#### `outputs.tf`
- `arn`, `arn_without_revision`, `family`, `revision`.
- `execution_role_arn`, `task_role_arn` — created or passed-through role ARNs.

#### `main.tf`
- `aws_ecs_task_definition.this` — `dynamic` blocks for `volume`, `runtime_platform`, `ephemeral_storage`, `placement_constraints`, `proxy_configuration`; `execution_role_arn` / `task_role_arn` resolved from created modules or caller inputs.
- `module "execution_role"` / `module "task_role"` (`modules/aws/iam/role`) — conditional on the respective `create_*` toggles; no inline `aws_iam_role`.
- Single resource per block; callers scale via `for_each` on the module (see Open questions for an optional internal map input).

### `modules/aws/ecs/service`
#### `variables.tf`
- `name` — `string` — Service name.
- `cluster_arn` — `string` — Target cluster (`cluster`).
- `task_definition_arn` — `string` — Task definition (`task_definition`).
- `desired_count` — `number`, default `2`.
- `launch_type` — `string`, default `null` — Mutually exclusive with `capacity_provider_strategy`.
- `capacity_provider_strategy` — `list(object({ capacity_provider = string, base = optional(number), weight = optional(number) }))`, default `[]`.
- `platform_version` — `string`, default `null`; `scheduling_strategy` — `string`, default `"REPLICA"`.
- Networking (`network_configuration`):
  - `subnet_ids` — `list(string)`.
  - `security_group_ids` — `list(string)`, default `[]`.
  - `assign_public_ip` — `bool`, default `false`.
  - `create_security_group` — `bool`, default `false`; `vpc_id` — `string`, default `null`; `security_group_rules` — `any`, default `{}` — Compose `modules/aws/security_group` when `create_security_group = true`.
- `load_balancers` — `list(object({ target_group_arn = optional(string), elb_name = optional(string), container_name = string, container_port = number }))`, default `[]`.
- `service_registries` — `object({ registry_arn = string, port = optional(number), container_name = optional(string), container_port = optional(number) })`, default `null`.
- `service_connect_configuration` — `object({ enabled = optional(bool, true), namespace = optional(string), log_configuration = optional(any), services = optional(list(any), []) })`, default `null`.
- Deployment safety (secure defaults):
  - `enable_deployment_circuit_breaker` — `bool`, default `true`; `deployment_circuit_breaker_rollback` — `bool`, default `true`.
  - `deployment_minimum_healthy_percent` — `number`, default `100`; `deployment_maximum_percent` — `number`, default `200`.
  - `deployment_controller_type` — `string`, default `"ECS"`.
  - `deployment_alarms` — `object({ alarm_names = list(string), enable = bool, rollback = bool })`, default `null`.
- `ordered_placement_strategy` — `list(object({ type = string, field = optional(string) }))`, default `[]`.
- `placement_constraints` — `list(object({ type = string, expression = optional(string) }))`, default `[]`.
- `enable_execute_command` — `bool`, default `false`.
- `enable_ecs_managed_tags` — `bool`, default `true`; `propagate_tags` — `string`, default `"SERVICE"`.
- `health_check_grace_period_seconds` — `number`, default `null`.
- `wait_for_steady_state` — `bool`, default `false`; `force_new_deployment` — `bool`, default `false`; `force_delete` — `bool`, default `null`.
- `availability_zone_rebalancing` — `string`, default `null`.
- `triggers` — `map(string)`, default `{}`.
- `ignore_desired_count` — `bool`, default `false` — Toggle a `lifecycle { ignore_changes = [desired_count] }` for callers using external autoscaling (see Open questions).
- `tags` — `map(string)`, default `{}`.

#### `outputs.tf`
- `id`, `name`, `cluster`, `desired_count`.
- `security_group_id` — created service SG when `create_security_group = true`.

#### `main.tf`
- `aws_ecs_service.this` — `network_configuration`; `dynamic` blocks for `capacity_provider_strategy`, `load_balancer`, `service_registries`, `service_connect_configuration`, `deployment_circuit_breaker`, `alarms`, `deployment_controller`, `ordered_placement_strategy`, `placement_constraints`; conditional `lifecycle.ignore_changes` driven by `ignore_desired_count`.
- `module "security_group"` (`modules/aws/security_group`) — conditional on `create_security_group`; no inline `aws_security_group`.
- Single resource per block; callers scale via `for_each` on the module (see Open questions).

### `modules/aws/ecs/namespace`
#### `variables.tf`
- `name` — `string` — Cloud Map HTTP namespace name.
- `description` — `string`, default `null`.
- `tags` — `map(string)`, default `{}`.

#### `outputs.tf`
- `id`, `arn` — referenced by the cluster (`service_connect_defaults`) and services (`service_connect_configuration`).

#### `main.tf`
- `aws_service_discovery_http_namespace.this` — single resource; callers scale via `for_each` on the module.

## 5. Breaking-change assessment
- Breaking: **no.**
- All five submodules are brand new and have no existing callers (nothing in
  `global/` or elsewhere references ECS today).
- No existing module is modified; cross-cutting modules (`iam/role`, `kms`,
  `cloudwatch/log_group`, `security_group`) are only consumed via composition.

## 6. Checkov / tfsec considerations
- New suppressions: **none added by default.** Secure defaults satisfy the
  common ECS checks directly — Container Insights enabled (CKV_AWS_65),
  separate task vs. execution roles (CKV_AWS_249), and KMS-encrypted
  exec-command CloudWatch logging (CKV_AWS_158) are on by default.
- Possible suppressions, added inline **with documented rationale only if CI
  flags them**, because `container_definitions` is a caller-supplied JSON
  document the module cannot introspect or enforce (consistent with the repo's
  "module library — security is the caller's responsibility" posture in
  `AGENTS.md`):
  - Container-definition-level checks such as read-only root filesystem
    (CKV_AWS_336), plaintext environment secrets, and non-root user.
  - EFS volume transit encryption (CKV_AWS_97) when a caller supplies a volume
    that disables it (the module defaults transit encryption on).
- Existing suppressions affected: none.

## 7. terraform-docs impact
- New `<!-- BEGIN_TF_DOCS -->` blocks are injected into all five new READMEs
  (`modules/aws/ecs/{cluster,capacity_provider,task_definition,service,namespace}/README.md`)
  during implementation and verified by the `Verify - terraform-docs` CI job.
- No existing module README changes, since the change is purely additive.

## 8. Testing
- `tofu -chdir=modules/aws/ecs/<submodule> init -backend=false && tofu -chdir=modules/aws/ecs/<submodule> validate` for each of the five submodules.
- `tofu fmt -check -diff -recursive` is clean.
- `terraform-docs markdown table --output-file README.md --output-mode inject modules/aws/ecs/<submodule>` for each submodule, or `pre-commit run --all-files`.
- `checkov -d modules/aws/ecs` (locally; CI runs on schedule).
- Module-specific: confirm a Fargate `cluster` + `namespace` + `task_definition`
  + `service` compose end-to-end via `module {}` blocks; confirm the cluster
  wires `service_connect_defaults` to the namespace ARN and the service wires
  `service_connect_configuration`; confirm deployment circuit breaker + rollback
  default on; confirm `assign_public_ip = false` by default; confirm
  `create_*` composition toggles produce the IAM roles / KMS key / log group /
  security group via the existing child modules and not inline.

## 9. Open questions
- **Internal map inputs vs. caller `for_each`:** `service`, `task_definition`,
  and `namespace` are specified as single-resource modules scaled by `for_each`
  on the module block (satisfying `AGENTS.md` §5's "map or `for_each`" and
  matching the `modules/aws/budgets/budget` precedent). Should they instead
  accept an internal `map(object(...))` input? Preference: keep single-resource
  + caller `for_each` for clarity, revisit if a YAML-driven multi-service input
  is requested.
- **Application Auto Scaling:** Should the `service` submodule manage
  `aws_appautoscaling_target` / `aws_appautoscaling_policy`, or should that be a
  future `modules/aws/ecs/autoscaling` submodule? Preference: separate future
  submodule; the `ignore_desired_count` toggle is provided now so external
  autoscaling does not fight Terraform.
- **DNS-based service discovery:** Should `namespace` also cover
  `aws_service_discovery_private_dns_namespace` (and a `service_discovery`
  submodule for `aws_service_discovery_service`), or remain HTTP/Service-Connect
  only? Preference: HTTP-only now (per the issue), add DNS discovery later if
  requested.
- **Service security group ownership:** `create_security_group` defaults to
  `false` (callers pass `security_group_ids`, matching the issue example).
  Should the module instead default to creating a no-ingress SG for a
  more-secure out-of-the-box posture? Preference: keep `false` default but
  document the `create_security_group` path clearly.

## 10. Acceptance criteria
- `modules/aws/ecs/{cluster,capacity_provider,task_definition,service,namespace}/`
  each contain `main.tf`, `variables.tf`, `outputs.tf`, and `README.md`, started
  from `modules/module_template/`.
- **Clusters:** create `aws_ecs_cluster` with Container Insights enabled by
  default and encrypted execute-command logging; capacity providers managed via
  `aws_ecs_cluster_capacity_providers`.
- **Namespaces:** create a Cloud Map `aws_service_discovery_http_namespace` and
  wire it into `service_connect_defaults` (cluster) and
  `service_connect_configuration` (service).
- **Tasks:** create `aws_ecs_task_definition` (Fargate / `awsvpc` defaults) and
  run them via `aws_ecs_service` with deployment circuit breaker + rollback
  enabled by default.
- Cross-cutting IAM roles, KMS keys, security groups, and CloudWatch log groups
  are created by **calling the existing submodules** (`modules/aws/iam/role`,
  `modules/aws/kms`, `modules/aws/security_group`,
  `modules/aws/cloudwatch/log_group`) — not declared inline (`AGENTS.md` §2).
- Each submodule that can manage multiples supports `for_each` / map scaling
  (`AGENTS.md` §5).
- Secure / Well-Architected defaults: Container Insights `enabled`; exec-command
  logging encrypted with a KMS key; deployment circuit breaker + rollback
  enabled; `assign_public_ip = false`; least-privilege, separate task/execution
  roles via the IAM submodule.
- Each `README.md` includes a description, prerequisites, a complete `module {}`
  usage example, a notes/design-decisions section, and the auto-generated
  `terraform-docs` block.
- `tofu fmt -check -diff -recursive` is clean and `tofu -chdir=<submodule> validate`
  passes for every submodule; `terraform-docs` verification and Checkov pass in
  CI.
- No breaking changes to existing modules or callers.
