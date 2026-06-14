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
  # When a security group is created via composition, append its ID to any
  # caller-supplied security group IDs.
  security_group_ids = var.create_security_group ? concat(var.security_group_ids, [module.security_group[0].id]) : var.security_group_ids
}

###########################
# Security Group (composition)
###########################

module "security_group" {
  count  = var.create_security_group ? 1 : 0
  source = "../../security_group"

  name        = "${var.name}-service"
  description = "Security group for ECS service ${var.name}."
  vpc_id      = var.vpc_id
  tags        = merge(tomap({ Name = "${var.name}-service" }), var.tags)
}

###########################
# ECS Service (managed desired_count)
###########################

resource "aws_ecs_service" "this" {
  count = var.ignore_desired_count ? 0 : 1

  name                               = var.name
  cluster                            = var.cluster_arn
  task_definition                    = var.task_definition_arn
  desired_count                      = var.desired_count
  launch_type                        = var.launch_type
  platform_version                   = var.platform_version
  scheduling_strategy                = var.scheduling_strategy
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  propagate_tags                     = var.propagate_tags
  enable_execute_command             = var.enable_execute_command
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  wait_for_steady_state              = var.wait_for_steady_state
  force_new_deployment               = var.force_new_deployment
  force_delete                       = var.force_delete
  availability_zone_rebalancing      = var.availability_zone_rebalancing
  triggers                           = var.triggers

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = local.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      base              = capacity_provider_strategy.value.base
      weight            = capacity_provider_strategy.value.weight
    }
  }

  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      elb_name         = load_balancer.value.elb_name
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries != null ? [var.service_registries] : []
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = service_registries.value.port
      container_name = service_registries.value.container_name
      container_port = service_registries.value.container_port
    }
  }

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_configuration != null ? [var.service_connect_configuration] : []
    content {
      enabled   = service_connect_configuration.value.enabled
      namespace = service_connect_configuration.value.namespace

      dynamic "log_configuration" {
        for_each = service_connect_configuration.value.log_configuration != null ? [service_connect_configuration.value.log_configuration] : []
        content {
          log_driver = log_configuration.value.log_driver
          options    = log_configuration.value.options

          dynamic "secret_option" {
            for_each = log_configuration.value.secret_option
            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }

      dynamic "service" {
        for_each = service_connect_configuration.value.service
        content {
          port_name             = service.value.port_name
          discovery_name        = service.value.discovery_name
          ingress_port_override = service.value.ingress_port_override

          dynamic "client_alias" {
            for_each = service.value.client_alias != null ? [service.value.client_alias] : []
            content {
              port     = client_alias.value.port
              dns_name = client_alias.value.dns_name
            }
          }

          dynamic "timeout" {
            for_each = service.value.timeout != null ? [service.value.timeout] : []
            content {
              idle_timeout_seconds        = timeout.value.idle_timeout_seconds
              per_request_timeout_seconds = timeout.value.per_request_timeout_seconds
            }
          }

          dynamic "tls" {
            for_each = service.value.tls != null ? [service.value.tls] : []
            content {
              kms_key  = tls.value.kms_key
              role_arn = tls.value.role_arn
              issuer_cert_authority {
                aws_pca_authority_arn = tls.value.issuer_cert_authority.aws_pca_authority_arn
              }
            }
          }
        }
      }
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.enable_deployment_circuit_breaker ? [1] : []
    content {
      enable   = true
      rollback = var.deployment_circuit_breaker_rollback
    }
  }

  dynamic "alarms" {
    for_each = var.deployment_alarms != null ? [var.deployment_alarms] : []
    content {
      alarm_names = alarms.value.alarm_names
      enable      = alarms.value.enable
      rollback    = alarms.value.rollback
    }
  }

  dynamic "deployment_controller" {
    for_each = var.deployment_controller_type != null ? [1] : []
    content {
      type = var.deployment_controller_type
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  tags = merge(tomap({ Name = var.name }), var.tags)
}

###########################
# ECS Service (ignored desired_count)
###########################

# Identical to aws_ecs_service.this, but ignores desired_count so external
# autoscaling (e.g. Application Auto Scaling) does not fight Terraform. Selected
# when var.ignore_desired_count = true.
resource "aws_ecs_service" "ignore_desired_count" {
  count = var.ignore_desired_count ? 1 : 0

  name                               = var.name
  cluster                            = var.cluster_arn
  task_definition                    = var.task_definition_arn
  desired_count                      = var.desired_count
  launch_type                        = var.launch_type
  platform_version                   = var.platform_version
  scheduling_strategy                = var.scheduling_strategy
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  enable_ecs_managed_tags            = var.enable_ecs_managed_tags
  propagate_tags                     = var.propagate_tags
  enable_execute_command             = var.enable_execute_command
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds
  wait_for_steady_state              = var.wait_for_steady_state
  force_new_deployment               = var.force_new_deployment
  force_delete                       = var.force_delete
  availability_zone_rebalancing      = var.availability_zone_rebalancing
  triggers                           = var.triggers

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = local.security_group_ids
    assign_public_ip = var.assign_public_ip
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      base              = capacity_provider_strategy.value.base
      weight            = capacity_provider_strategy.value.weight
    }
  }

  dynamic "load_balancer" {
    for_each = var.load_balancers
    content {
      target_group_arn = load_balancer.value.target_group_arn
      elb_name         = load_balancer.value.elb_name
      container_name   = load_balancer.value.container_name
      container_port   = load_balancer.value.container_port
    }
  }

  dynamic "service_registries" {
    for_each = var.service_registries != null ? [var.service_registries] : []
    content {
      registry_arn   = service_registries.value.registry_arn
      port           = service_registries.value.port
      container_name = service_registries.value.container_name
      container_port = service_registries.value.container_port
    }
  }

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_configuration != null ? [var.service_connect_configuration] : []
    content {
      enabled   = service_connect_configuration.value.enabled
      namespace = service_connect_configuration.value.namespace

      dynamic "log_configuration" {
        for_each = service_connect_configuration.value.log_configuration != null ? [service_connect_configuration.value.log_configuration] : []
        content {
          log_driver = log_configuration.value.log_driver
          options    = log_configuration.value.options

          dynamic "secret_option" {
            for_each = log_configuration.value.secret_option
            content {
              name       = secret_option.value.name
              value_from = secret_option.value.value_from
            }
          }
        }
      }

      dynamic "service" {
        for_each = service_connect_configuration.value.service
        content {
          port_name             = service.value.port_name
          discovery_name        = service.value.discovery_name
          ingress_port_override = service.value.ingress_port_override

          dynamic "client_alias" {
            for_each = service.value.client_alias != null ? [service.value.client_alias] : []
            content {
              port     = client_alias.value.port
              dns_name = client_alias.value.dns_name
            }
          }

          dynamic "timeout" {
            for_each = service.value.timeout != null ? [service.value.timeout] : []
            content {
              idle_timeout_seconds        = timeout.value.idle_timeout_seconds
              per_request_timeout_seconds = timeout.value.per_request_timeout_seconds
            }
          }

          dynamic "tls" {
            for_each = service.value.tls != null ? [service.value.tls] : []
            content {
              kms_key  = tls.value.kms_key
              role_arn = tls.value.role_arn
              issuer_cert_authority {
                aws_pca_authority_arn = tls.value.issuer_cert_authority.aws_pca_authority_arn
              }
            }
          }
        }
      }
    }
  }

  dynamic "deployment_circuit_breaker" {
    for_each = var.enable_deployment_circuit_breaker ? [1] : []
    content {
      enable   = true
      rollback = var.deployment_circuit_breaker_rollback
    }
  }

  dynamic "alarms" {
    for_each = var.deployment_alarms != null ? [var.deployment_alarms] : []
    content {
      alarm_names = alarms.value.alarm_names
      enable      = alarms.value.enable
      rollback    = alarms.value.rollback
    }
  }

  dynamic "deployment_controller" {
    for_each = var.deployment_controller_type != null ? [1] : []
    content {
      type = var.deployment_controller_type
    }
  }

  dynamic "ordered_placement_strategy" {
    for_each = var.ordered_placement_strategy
    content {
      type  = ordered_placement_strategy.value.type
      field = ordered_placement_strategy.value.field
    }
  }

  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  tags = merge(tomap({ Name = var.name }), var.tags)

  lifecycle {
    ignore_changes = [desired_count]
  }
}
