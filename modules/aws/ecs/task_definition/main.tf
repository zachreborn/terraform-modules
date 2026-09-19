###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0: several input object types (volumes, runtime_platform, etc.)
  # use optional() attributes (stable since Terraform 1.3 / OpenTofu 1.6).
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

###########################
# Data Sources
###########################

# Trust policy allowing ECS tasks to assume the execution and task roles.
data "aws_iam_policy_document" "assume_role" {
  count = (var.create_execution_role || var.create_task_role) ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

###########################
# Locals
###########################

locals {
  execution_role_arn = var.create_execution_role ? module.execution_role[0].arn : var.execution_role_arn
  task_role_arn      = var.create_task_role ? module.task_role[0].arn : var.task_role_arn

  # Attach the optional least-privilege inline policy (created via the iam/policy
  # module) to the task role when supplied. Must gate on the same condition as
  # the task_role_policy module's own count (create_task_role AND
  # task_role_policy_json != null) -- checking task_role_policy_json alone
  # indexes module.task_role_policy[0] even when create_task_role = false and
  # that module was never created.
  task_role_policy_arns = (var.create_task_role && var.task_role_policy_json != null) ? [module.task_role_policy[0].arn] : []
}

###########################
# Execution Role (composition)
###########################

module "execution_role" {
  count  = var.create_execution_role ? 1 : 0
  source = "../../iam/role"

  name               = "${var.family}-execution"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  policy_arns        = var.execution_role_managed_policy_arns
  tags               = merge(tomap({ Name = "${var.family}-execution" }), var.tags)
}

###########################
# Task Role (composition)
###########################

module "task_role_policy" {
  count  = var.create_task_role && var.task_role_policy_json != null ? 1 : 0
  source = "../../iam/policy"

  name        = "${var.family}-task"
  description = "Least-privilege task role policy for ECS task definition ${var.family}."
  policy      = var.task_role_policy_json
  tags        = merge(tomap({ Name = "${var.family}-task" }), var.tags)
}

module "task_role" {
  count  = var.create_task_role ? 1 : 0
  source = "../../iam/role"

  name               = "${var.family}-task"
  assume_role_policy = data.aws_iam_policy_document.assume_role[0].json
  policy_arns        = local.task_role_policy_arns
  tags               = merge(tomap({ Name = "${var.family}-task" }), var.tags)
}

###########################
# ECS Task Definition
###########################

resource "aws_ecs_task_definition" "this" {
  family = var.family

  # volumes' efs_volume_configuration defaults transit_encryption to "ENABLED" via the
  # optional(string, "ENABLED") type constraint. Checkov cannot resolve the object-type
  # default through the caller-supplied list(object) var.volumes and the nested dynamic
  # volume/efs_volume_configuration blocks.
  # checkov:skip=CKV_AWS_97:volumes' efs_volume_configuration defaults transit_encryption to "ENABLED"; Checkov cannot resolve the object-type default through list(object) var.volumes and the nested dynamic volume/efs_volume_configuration blocks

  container_definitions    = var.container_definitions
  cpu                      = var.cpu
  memory                   = var.memory
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  execution_role_arn       = local.execution_role_arn
  task_role_arn            = local.task_role_arn
  ipc_mode                 = var.ipc_mode
  pid_mode                 = var.pid_mode
  skip_destroy             = var.skip_destroy
  track_latest             = var.track_latest

  dynamic "runtime_platform" {
    for_each = var.runtime_platform != null ? [var.runtime_platform] : []
    content {
      operating_system_family = runtime_platform.value.operating_system_family
      cpu_architecture        = runtime_platform.value.cpu_architecture
    }
  }

  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size_in_gib != null ? [1] : []
    content {
      size_in_gib = var.ephemeral_storage_size_in_gib
    }
  }

  dynamic "proxy_configuration" {
    for_each = var.proxy_configuration != null ? [var.proxy_configuration] : []
    content {
      type           = proxy_configuration.value.type
      container_name = proxy_configuration.value.container_name
      properties     = proxy_configuration.value.properties
    }
  }

  dynamic "placement_constraints" {
    for_each = var.placement_constraints
    content {
      type       = placement_constraints.value.type
      expression = placement_constraints.value.expression
    }
  }

  dynamic "volume" {
    for_each = var.volumes
    content {
      name                = volume.value.name
      host_path           = volume.value.host_path
      configure_at_launch = volume.value.configure_at_launch

      dynamic "docker_volume_configuration" {
        for_each = volume.value.docker_volume_configuration != null ? [volume.value.docker_volume_configuration] : []
        content {
          scope         = docker_volume_configuration.value.scope
          autoprovision = docker_volume_configuration.value.autoprovision
          driver        = docker_volume_configuration.value.driver
          driver_opts   = docker_volume_configuration.value.driver_opts
          labels        = docker_volume_configuration.value.labels
        }
      }

      dynamic "efs_volume_configuration" {
        for_each = volume.value.efs_volume_configuration != null ? [volume.value.efs_volume_configuration] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = efs_volume_configuration.value.root_directory
          transit_encryption      = efs_volume_configuration.value.transit_encryption
          transit_encryption_port = efs_volume_configuration.value.transit_encryption_port

          dynamic "authorization_config" {
            for_each = efs_volume_configuration.value.authorization_config != null ? [efs_volume_configuration.value.authorization_config] : []
            content {
              access_point_id = authorization_config.value.access_point_id
              iam             = authorization_config.value.iam
            }
          }
        }
      }

      dynamic "fsx_windows_file_server_volume_configuration" {
        for_each = volume.value.fsx_windows_file_server_volume_configuration != null ? [volume.value.fsx_windows_file_server_volume_configuration] : []
        content {
          file_system_id = fsx_windows_file_server_volume_configuration.value.file_system_id
          root_directory = fsx_windows_file_server_volume_configuration.value.root_directory

          authorization_config {
            credentials_parameter = fsx_windows_file_server_volume_configuration.value.authorization_config.credentials_parameter
            domain                = fsx_windows_file_server_volume_configuration.value.authorization_config.domain
          }
        }
      }
    }
  }

  enable_fault_injection = var.enable_fault_injection

  tags = merge(tomap({ Name = var.family }), var.tags)

  # task_role_policy_json only applies to the task role this module creates.
  # Supplying it while create_task_role = false is a configuration error --
  # reject it explicitly rather than silently ignoring the caller's intent.
  lifecycle {
    precondition {
      condition     = var.create_task_role || var.task_role_policy_json == null
      error_message = "task_role_policy_json requires create_task_role = true (it configures the task role this module creates)."
    }
  }
}
