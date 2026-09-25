###########################
# Provider Configuration
###########################
terraform {
  # >= 1.3.0: optional() attributes are used throughout the target_*_parameters
  # object type constraints in variables.tf.
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # >= 6.14.0: action_after_completion was added to aws_scheduler_schedule in
      # hashicorp/aws v6.14.0 (https://github.com/hashicorp/terraform-provider-aws/pull/44264).
      version = ">= 6.14.0"
    }
  }
}

###########################
# Data Sources
###########################
# Only queried when this module creates the invoke role, so a caller supplying
# target_role_arn incurs no extra API calls.

data "aws_caller_identity" "current" {
  count = local.create_target_role ? 1 : 0
}

data "aws_partition" "current" {
  count = local.create_target_role ? 1 : 0
}

data "aws_region" "current" {
  count = local.create_target_role ? 1 : 0
}

###########################
# Locals
###########################

locals {
  create_target_role = var.target_role_arn == null

  # Wrapped in try() because P1 (exactly one of name/name_prefix) is enforced as a
  # lifecycle precondition below, not a validation block (cross-variable checks
  # require Terraform >= 1.9). Without try(), an invalid all-null combination would
  # crash coalesce() here before the precondition ever gets a chance to report its
  # own clear error message.
  schedule_name_label = try(coalesce(var.name, var.name_prefix), "unnamed")

  target_service = split(":", var.target_arn)[2]

  # Static map of target service namespace -> least-privilege invoke action.
  # ECS and universal targets are deliberately absent: their required action
  # cannot be derived from target_arn alone (see precondition P3 below), so the
  # caller must supply target_role_policy_actions for those targets.
  derivable_target_actions = {
    lambda       = "lambda:InvokeFunction"
    sqs          = "sqs:SendMessage"
    sns          = "sns:Publish"
    states       = "states:StartExecution"
    kinesis      = "kinesis:PutRecord"
    firehose     = "firehose:PutRecord"
    events       = "events:PutEvents"
    codebuild    = "codebuild:StartBuild"
    codepipeline = "codepipeline:StartPipelineExecution"
    sagemaker    = "sagemaker:StartPipelineExecution"
  }

  derived_target_action = lookup(local.derivable_target_actions, local.target_service, null)

  # Deliberately not coalesce(): when the target service isn't derivable (ECS,
  # universal targets) and the caller hasn't supplied target_role_policy_actions,
  # this must resolve to null rather than crash -- precondition P3 below is what
  # turns that combination into a clear, plan-time error message.
  invoke_policy_actions = var.target_role_policy_actions != null ? var.target_role_policy_actions : (
    local.derived_target_action != null ? [local.derived_target_action] : null
  )
  invoke_policy_resources = coalesce(var.target_role_policy_resources, [var.target_arn])

  target_role_name_prefix = var.target_role_name == null ? substr("${local.schedule_name_label}-scheduler-", 0, 38) : null

  # The schedule's own ARN is only knowable at plan time when var.name is set (a
  # name generated from name_prefix isn't known until apply), so the SourceArn
  # trust-policy condition is only added in that case.
  schedule_arn_known = local.create_target_role && var.name != null

  assume_role_policy_json = local.create_target_role ? jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowSchedulerAssumeRole"
        Effect    = "Allow"
        Action    = "sts:AssumeRole"
        Principal = { Service = "scheduler.amazonaws.com" }
        Condition = merge(
          {
            StringEquals = {
              "aws:SourceAccount" = data.aws_caller_identity.current[0].account_id
            }
          },
          local.schedule_arn_known ? {
            ArnEquals = {
              "aws:SourceArn" = "arn:${data.aws_partition.current[0].partition}:scheduler:${data.aws_region.current[0].region}:${data.aws_caller_identity.current[0].account_id}:schedule/${coalesce(var.group_name, "default")}/${var.name}"
            }
          } : {}
        )
      }
    ]
  }) : null

  invoke_policy_json = local.create_target_role ? jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid      = "AllowScheduleTargetInvoke"
          Effect   = "Allow"
          Action   = local.invoke_policy_actions
          Resource = local.invoke_policy_resources
        }
      ],
      var.target_dead_letter_arn != null ? [
        {
          Sid      = "AllowScheduleDeadLetterQueueSend"
          Effect   = "Allow"
          Action   = "sqs:SendMessage"
          Resource = var.target_dead_letter_arn
        }
      ] : []
    )
  }) : null

  target_role_arn = local.create_target_role ? module.target_role[0].arn : var.target_role_arn
}

###########################
# Composed Invoke Role (composition)
###########################

module "target_invoke_policy" {
  count  = local.create_target_role ? 1 : 0
  source = "../iam/policy"

  name        = var.target_role_name
  name_prefix = var.target_role_name == null ? local.target_role_name_prefix : null
  description = "Least-privilege EventBridge Scheduler invoke policy for ${local.schedule_name_label}."
  path        = var.target_role_path
  policy      = local.invoke_policy_json
  tags        = merge(tomap({ Name = local.schedule_name_label }), var.tags)
}

module "target_role" {
  count  = local.create_target_role ? 1 : 0
  source = "../iam/role"

  name                 = var.target_role_name
  name_prefix          = var.target_role_name == null ? local.target_role_name_prefix : null
  assume_role_policy   = local.assume_role_policy_json
  policy_arns          = concat([module.target_invoke_policy[0].arn], var.target_role_additional_policy_arns)
  path                 = var.target_role_path
  permissions_boundary = var.target_role_permissions_boundary
  max_session_duration = var.target_role_max_session_duration
  tags                 = merge(tomap({ Name = local.schedule_name_label }), var.tags)
}

###########################
# EventBridge Scheduler Schedule
###########################
# No lifecycle.ignore_changes: nothing on this resource is mutated outside
# Terraform, so the repo's aws_instance-style ignore pattern does not apply here.
# No tags argument: aws_scheduler_schedule accepts no tags (see var.tags).

resource "aws_scheduler_schedule" "this" {
  action_after_completion      = var.action_after_completion
  description                  = var.description
  end_date                     = var.end_date
  group_name                   = var.group_name
  kms_key_arn                  = var.kms_key_arn
  name                         = var.name
  name_prefix                  = var.name_prefix
  region                       = var.region
  schedule_expression          = var.schedule_expression
  schedule_expression_timezone = var.schedule_expression_timezone
  start_date                   = var.start_date
  state                        = var.state

  flexible_time_window {
    mode                      = var.flexible_time_window.mode
    maximum_window_in_minutes = var.flexible_time_window.maximum_window_in_minutes
  }

  target {
    arn      = var.target_arn
    input    = var.target_input
    role_arn = local.target_role_arn

    dynamic "dead_letter_config" {
      for_each = var.target_dead_letter_arn != null ? [var.target_dead_letter_arn] : []
      content {
        arn = dead_letter_config.value
      }
    }

    dynamic "ecs_parameters" {
      for_each = var.target_ecs_parameters != null ? [var.target_ecs_parameters] : []
      content {
        enable_ecs_managed_tags = ecs_parameters.value.enable_ecs_managed_tags
        enable_execute_command  = ecs_parameters.value.enable_execute_command
        group                   = ecs_parameters.value.group
        launch_type             = ecs_parameters.value.launch_type
        platform_version        = ecs_parameters.value.platform_version
        propagate_tags          = ecs_parameters.value.propagate_tags
        reference_id            = ecs_parameters.value.reference_id
        tags                    = ecs_parameters.value.tags
        task_count              = ecs_parameters.value.task_count
        task_definition_arn     = ecs_parameters.value.task_definition_arn

        dynamic "capacity_provider_strategy" {
          for_each = ecs_parameters.value.capacity_provider_strategy
          content {
            base              = capacity_provider_strategy.value.base
            capacity_provider = capacity_provider_strategy.value.capacity_provider
            weight            = capacity_provider_strategy.value.weight
          }
        }

        dynamic "network_configuration" {
          for_each = ecs_parameters.value.network_configuration != null ? [ecs_parameters.value.network_configuration] : []
          content {
            assign_public_ip = network_configuration.value.assign_public_ip
            security_groups  = network_configuration.value.security_groups
            subnets          = network_configuration.value.subnets
          }
        }

        dynamic "placement_constraints" {
          for_each = ecs_parameters.value.placement_constraints
          content {
            expression = placement_constraints.value.expression
            type       = placement_constraints.value.type
          }
        }

        dynamic "placement_strategy" {
          for_each = ecs_parameters.value.placement_strategy
          content {
            field = placement_strategy.value.field
            type  = placement_strategy.value.type
          }
        }
      }
    }

    dynamic "eventbridge_parameters" {
      for_each = var.target_eventbridge_parameters != null ? [var.target_eventbridge_parameters] : []
      content {
        detail_type = eventbridge_parameters.value.detail_type
        source      = eventbridge_parameters.value.source
      }
    }

    dynamic "kinesis_parameters" {
      for_each = var.target_kinesis_parameters != null ? [var.target_kinesis_parameters] : []
      content {
        partition_key = kinesis_parameters.value.partition_key
      }
    }

    dynamic "retry_policy" {
      for_each = var.target_retry_policy != null ? [var.target_retry_policy] : []
      content {
        maximum_event_age_in_seconds = retry_policy.value.maximum_event_age_in_seconds
        maximum_retry_attempts       = retry_policy.value.maximum_retry_attempts
      }
    }

    dynamic "sagemaker_pipeline_parameters" {
      for_each = var.target_sagemaker_pipeline_parameters != null ? [var.target_sagemaker_pipeline_parameters] : []
      content {
        dynamic "pipeline_parameter" {
          for_each = sagemaker_pipeline_parameters.value.pipeline_parameter
          content {
            name  = pipeline_parameter.value.name
            value = pipeline_parameter.value.value
          }
        }
      }
    }

    dynamic "sqs_parameters" {
      for_each = var.target_sqs_parameters != null ? [var.target_sqs_parameters] : []
      content {
        message_group_id = sqs_parameters.value.message_group_id
      }
    }
  }

  lifecycle {
    # P1: exactly one of name / name_prefix must be set.
    precondition {
      condition     = (var.name != null) != (var.name_prefix != null)
      error_message = "Exactly one of name or name_prefix must be set."
    }

    # P2: at most one of the five templated target_*_parameters may be set.
    precondition {
      condition = length(compact([
        var.target_ecs_parameters != null ? "ecs" : "",
        var.target_eventbridge_parameters != null ? "eventbridge" : "",
        var.target_kinesis_parameters != null ? "kinesis" : "",
        var.target_sagemaker_pipeline_parameters != null ? "sagemaker" : "",
        var.target_sqs_parameters != null ? "sqs" : "",
      ])) <= 1
      error_message = "At most one of target_ecs_parameters, target_eventbridge_parameters, target_kinesis_parameters, target_sagemaker_pipeline_parameters, or target_sqs_parameters may be set."
    }

    # P3: when this module creates the invoke role and the caller hasn't supplied
    # explicit actions, the target service must be one this module can derive an
    # action for (ECS and universal targets are not derivable -- see the comment
    # on local.derivable_target_actions).
    precondition {
      condition     = !(local.create_target_role && var.target_role_policy_actions == null) || contains(keys(local.derivable_target_actions), local.target_service)
      error_message = "The invoke action for target service '${local.target_service}' cannot be derived automatically (expected for ECS and universal targets). Set target_role_policy_actions (and usually target_role_policy_resources) explicitly, or supply target_role_arn."
    }

    # P4: end_date must be strictly later than start_date when both are set.
    # HCL's comparison operators only work on numbers, not strings, so RFC3339
    # timestamps must be compared with timecmp() (available since Terraform/
    # OpenTofu 1.3.0, already this module's floor for optional() attributes).
    precondition {
      condition     = var.start_date == null || var.end_date == null || timecmp(var.end_date, var.start_date) > 0
      error_message = "end_date must be strictly later than start_date when both are set."
    }
  }
}
