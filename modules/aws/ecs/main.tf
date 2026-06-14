###########################
# Provider Configuration
###########################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Locals
###########################

locals {
  create_namespace = var.namespace != null

  # The effective namespace ARN is the created namespace, or an existing one
  # supplied by the caller.
  namespace_arn = local.create_namespace ? module.namespace[0].arn : var.existing_namespace_arn

  default_capacity_provider_strategy = [
    {
      capacity_provider = "FARGATE"
      base              = 1
      weight            = 100
    }
  ]

  # Names of the EC2 capacity providers created via composition.
  created_capacity_provider_names = [for k, m in module.capacity_provider : m.name]

  # Merge created EC2 capacity-provider names into the cluster's provider list.
  cluster_capacity_providers = distinct(concat(
    try(var.cluster.capacity_providers, ["FARGATE", "FARGATE_SPOT"]),
    local.created_capacity_provider_names,
  ))
}

###########################
# Namespace (composition)
###########################

module "namespace" {
  count  = local.create_namespace ? 1 : 0
  source = "./namespace"

  name        = var.namespace.name
  description = try(var.namespace.description, null)
  tags        = var.tags
}

###########################
# Capacity Providers (composition)
###########################

module "capacity_provider" {
  for_each = var.capacity_providers
  source   = "./capacity_provider"

  name                           = try(each.value.name, each.key)
  auto_scaling_group_arn         = each.value.auto_scaling_group_arn
  managed_draining               = try(each.value.managed_draining, "ENABLED")
  managed_termination_protection = try(each.value.managed_termination_protection, "ENABLED")
  managed_scaling                = try(each.value.managed_scaling, {})
  tags                           = merge(var.tags, try(each.value.tags, {}))
}

###########################
# Cluster (composition)
###########################

module "cluster" {
  source = "./cluster"

  name                          = var.cluster.name
  container_insights            = try(var.cluster.container_insights, "enabled")
  additional_settings           = try(var.cluster.additional_settings, [])
  service_connect_namespace_arn = local.namespace_arn

  capacity_providers                 = local.cluster_capacity_providers
  default_capacity_provider_strategy = try(var.cluster.default_capacity_provider_strategy, local.default_capacity_provider_strategy)

  enable_execute_command_logging = try(var.cluster.enable_execute_command_logging, true)
  execute_command_logging        = try(var.cluster.execute_command_logging, "OVERRIDE")
  create_kms_key                 = try(var.cluster.create_kms_key, true)
  kms_key_arn                    = try(var.cluster.kms_key_arn, null)
  create_cloud_watch_log_group   = try(var.cluster.create_cloud_watch_log_group, true)
  cloud_watch_log_group_name     = try(var.cluster.cloud_watch_log_group_name, null)
  cloud_watch_encryption_enabled = try(var.cluster.cloud_watch_encryption_enabled, true)
  log_group_retention_in_days    = try(var.cluster.log_group_retention_in_days, 365)
  s3_bucket_name                 = try(var.cluster.s3_bucket_name, null)
  s3_key_prefix                  = try(var.cluster.s3_key_prefix, null)
  s3_bucket_encryption_enabled   = try(var.cluster.s3_bucket_encryption_enabled, true)
  managed_storage_kms_key_arn    = try(var.cluster.managed_storage_kms_key_arn, null)

  tags = merge(var.tags, try(var.cluster.tags, {}))
}

###########################
# Task Definitions (composition)
###########################

module "task_definition" {
  for_each = var.task_definitions
  source   = "./task_definition"

  family                        = try(each.value.family, each.key)
  container_definitions         = each.value.container_definitions
  cpu                           = try(each.value.cpu, null)
  memory                        = try(each.value.memory, null)
  network_mode                  = try(each.value.network_mode, "awsvpc")
  requires_compatibilities      = try(each.value.requires_compatibilities, ["FARGATE"])
  runtime_platform              = try(each.value.runtime_platform, null)
  ephemeral_storage_size_in_gib = try(each.value.ephemeral_storage_size_in_gib, null)
  volumes                       = try(each.value.volumes, [])
  placement_constraints         = try(each.value.placement_constraints, [])
  proxy_configuration           = try(each.value.proxy_configuration, null)
  ipc_mode                      = try(each.value.ipc_mode, null)
  pid_mode                      = try(each.value.pid_mode, null)
  skip_destroy                  = try(each.value.skip_destroy, false)
  track_latest                  = try(each.value.track_latest, null)

  create_execution_role              = try(each.value.create_execution_role, true)
  execution_role_arn                 = try(each.value.execution_role_arn, null)
  execution_role_managed_policy_arns = try(each.value.execution_role_managed_policy_arns, ["arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"])
  create_task_role                   = try(each.value.create_task_role, true)
  task_role_arn                      = try(each.value.task_role_arn, null)
  task_role_policy_json              = try(each.value.task_role_policy_json, null)

  tags = merge(var.tags, try(each.value.tags, {}))
}

###########################
# Services (composition)
###########################

module "service" {
  for_each = var.services
  source   = "./service"

  name                = try(each.value.name, each.key)
  cluster_arn         = module.cluster.arn
  task_definition_arn = module.task_definition[each.value.task_definition].arn
  desired_count       = try(each.value.desired_count, 2)
  launch_type         = try(each.value.launch_type, null)

  capacity_provider_strategy = try(each.value.capacity_provider_strategy, [])
  platform_version           = try(each.value.platform_version, null)
  scheduling_strategy        = try(each.value.scheduling_strategy, "REPLICA")

  subnet_ids            = each.value.subnet_ids
  security_group_ids    = try(each.value.security_group_ids, [])
  assign_public_ip      = try(each.value.assign_public_ip, false)
  create_security_group = try(each.value.create_security_group, false)
  vpc_id                = try(each.value.vpc_id, null)
  security_group_rules  = try(each.value.security_group_rules, {})

  load_balancers     = try(each.value.load_balancers, [])
  service_registries = try(each.value.service_registries, null)

  # Auto-inject the resolved namespace ARN into the Service Connect configuration
  # unless the caller explicitly set one.
  service_connect_configuration = try(
    merge({ enabled = true, namespace = local.namespace_arn }, each.value.service_connect_configuration),
    local.namespace_arn != null ? { enabled = true, namespace = local.namespace_arn } : null,
  )

  enable_deployment_circuit_breaker   = try(each.value.enable_deployment_circuit_breaker, true)
  deployment_circuit_breaker_rollback = try(each.value.deployment_circuit_breaker_rollback, true)
  deployment_minimum_healthy_percent  = try(each.value.deployment_minimum_healthy_percent, 100)
  deployment_maximum_percent          = try(each.value.deployment_maximum_percent, 200)
  deployment_controller_type          = try(each.value.deployment_controller_type, "ECS")
  deployment_alarms                   = try(each.value.deployment_alarms, null)

  ordered_placement_strategy = try(each.value.ordered_placement_strategy, [])
  placement_constraints      = try(each.value.placement_constraints, [])

  enable_execute_command            = try(each.value.enable_execute_command, false)
  enable_ecs_managed_tags           = try(each.value.enable_ecs_managed_tags, true)
  propagate_tags                    = try(each.value.propagate_tags, "SERVICE")
  health_check_grace_period_seconds = try(each.value.health_check_grace_period_seconds, null)
  wait_for_steady_state             = try(each.value.wait_for_steady_state, false)
  force_new_deployment              = try(each.value.force_new_deployment, false)
  force_delete                      = try(each.value.force_delete, null)
  availability_zone_rebalancing     = try(each.value.availability_zone_rebalancing, null)
  triggers                          = try(each.value.triggers, {})
  ignore_desired_count              = try(each.value.ignore_desired_count, false)

  tags = merge(var.tags, try(each.value.tags, {}))
}
