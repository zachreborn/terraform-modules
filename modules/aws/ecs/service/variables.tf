###########################
# Service Variables
###########################

variable "name" {
  description = "(Required) The name of the ECS service and the value of its `Name` tag."
  type        = string
}

variable "cluster_arn" {
  description = "(Required) ARN of the ECS cluster on which to run the service."
  type        = string
}

variable "task_definition_arn" {
  description = "(Required) The family and revision (family:revision) or full ARN of the task definition to run."
  type        = string
}

variable "desired_count" {
  description = "(Optional) Number of instances of the task definition to place and keep running. Defaults to 2 for availability."
  type        = number
  default     = 2
}

variable "launch_type" {
  description = "(Optional) Launch type on which to run the service. Mutually exclusive with `capacity_provider_strategy`."
  type        = string
  default     = null
}

variable "capacity_provider_strategy" {
  description = "(Optional) Capacity provider strategy to use for the service. Mutually exclusive with `launch_type`."
  type = list(object({
    capacity_provider = string
    base              = optional(number)
    weight            = optional(number)
  }))
  default = []
}

variable "platform_version" {
  description = "(Optional) Platform version on which to run the service. Only applicable to Fargate."
  type        = string
  default     = null
}

variable "scheduling_strategy" {
  description = "(Optional) Scheduling strategy to use for the service. Valid values are `REPLICA` and `DAEMON`. Defaults to `REPLICA`."
  type        = string
  default     = "REPLICA"
}

###########################
# Networking Variables
###########################

variable "subnet_ids" {
  description = "(Required) Subnets associated with the task or service (network_configuration.subnets)."
  type        = list(string)
}

variable "security_group_ids" {
  description = "(Optional) Security groups associated with the task or service. If `create_security_group` is true, the created group's ID is appended to this list."
  type        = list(string)
  default     = []
}

variable "assign_public_ip" {
  description = "(Optional) Whether the task's elastic network interface receives a public IP address. Defaults to false for a secure posture."
  type        = bool
  default     = false
}

variable "create_security_group" {
  description = "(Optional) Whether to create a service security group via modules/aws/security_group. Defaults to false (callers pass `security_group_ids`)."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "(Optional) VPC ID used when `create_security_group = true`."
  type        = string
  default     = null
}

variable "security_group_rules" {
  description = "(Optional) Reserved for future rule management. The composed modules/aws/security_group module currently manages only the security group itself; manage rules on the caller side or via dedicated security group rule resources."
  type        = any
  default     = {}
}

###########################
# Load Balancing & Discovery Variables
###########################

variable "load_balancers" {
  description = "(Optional) Load balancer configuration blocks. Supply target group ARNs from the existing modules/aws/alb or modules/aws/lb modules."
  type = list(object({
    target_group_arn = optional(string)
    elb_name         = optional(string)
    container_name   = string
    container_port   = number
  }))
  default = []
}

variable "service_registries" {
  description = "(Optional) Service discovery registries for the service (service_registries block)."
  type = object({
    registry_arn   = string
    port           = optional(number)
    container_name = optional(string)
    container_port = optional(number)
  })
  default = null
}

variable "service_connect_configuration" {
  description = "(Optional) ECS Service Connect configuration. `namespace` is the Cloud Map namespace ARN (see modules/aws/ecs/namespace)."
  type = object({
    enabled   = optional(bool, true)
    namespace = optional(string)
    log_configuration = optional(object({
      log_driver = string
      options    = optional(map(string))
      secret_option = optional(list(object({
        name       = string
        value_from = string
      })), [])
    }))
    service = optional(list(object({
      port_name             = string
      discovery_name        = optional(string)
      ingress_port_override = optional(number)
      client_alias = optional(object({
        port     = number
        dns_name = optional(string)
      }))
      timeout = optional(object({
        idle_timeout_seconds        = optional(number)
        per_request_timeout_seconds = optional(number)
      }))
      tls = optional(object({
        kms_key  = optional(string)
        role_arn = optional(string)
        issuer_cert_authority = object({
          aws_pca_authority_arn = string
        })
      }))
    })), [])
  })
  default = null
}

###########################
# Deployment Safety Variables
###########################

variable "enable_deployment_circuit_breaker" {
  description = "(Optional) Whether to enable the ECS deployment circuit breaker. Defaults to true."
  type        = bool
  default     = true
}

variable "deployment_circuit_breaker_rollback" {
  description = "(Optional) Whether to enable automatic rollback on deployment failure when the circuit breaker is enabled. Defaults to true."
  type        = bool
  default     = true
}

variable "deployment_minimum_healthy_percent" {
  description = "(Optional) Lower limit (as a percentage of desired_count) of running tasks that must remain healthy during a deployment. Defaults to 100."
  type        = number
  default     = 100
}

variable "deployment_maximum_percent" {
  description = "(Optional) Upper limit (as a percentage of desired_count) of running tasks during a deployment. Defaults to 200."
  type        = number
  default     = 200
}

variable "deployment_controller_type" {
  description = "(Optional) Type of deployment controller. Valid values are `ECS`, `CODE_DEPLOY`, and `EXTERNAL`. Defaults to `ECS`."
  type        = string
  default     = "ECS"
}

variable "deployment_alarms" {
  description = "(Optional) CloudWatch alarms used to determine deployment failure and trigger rollback."
  type = object({
    alarm_names = list(string)
    enable      = bool
    rollback    = bool
  })
  default = null
}

###########################
# Placement Variables
###########################

variable "ordered_placement_strategy" {
  description = "(Optional) Service-level strategy rules taken into consideration during task placement. Maximum of 5."
  type = list(object({
    type  = string
    field = optional(string)
  }))
  default = []
}

variable "placement_constraints" {
  description = "(Optional) Rules taken into consideration during task placement. Maximum of 10."
  type = list(object({
    type       = string
    expression = optional(string)
  }))
  default = []
}

###########################
# Behaviour Variables
###########################

variable "enable_execute_command" {
  description = "(Optional) Whether to enable the ECS Exec (execute command) functionality for the service. Defaults to false."
  type        = bool
  default     = false
}

variable "enable_ecs_managed_tags" {
  description = "(Optional) Whether to enable Amazon ECS managed tags for the tasks within the service. Defaults to true."
  type        = bool
  default     = true
}

variable "propagate_tags" {
  description = "(Optional) Whether to propagate the tags from the task definition or the service to the tasks. Valid values are `SERVICE`, `TASK_DEFINITION`, and `NONE`. Defaults to `SERVICE`."
  type        = string
  default     = "SERVICE"
}

variable "health_check_grace_period_seconds" {
  description = "(Optional) Seconds to ignore failing load balancer health checks on newly instantiated tasks to prevent premature shutdown."
  type        = number
  default     = null
}

variable "wait_for_steady_state" {
  description = "(Optional) Whether Terraform should wait for the service to reach a steady state before continuing. Defaults to false."
  type        = bool
  default     = false
}

variable "force_new_deployment" {
  description = "(Optional) Whether to force a new task deployment of the service. Defaults to false."
  type        = bool
  default     = false
}

variable "force_delete" {
  description = "(Optional) Whether to allow Terraform to delete the service even if it was not scaled down to zero tasks."
  type        = bool
  default     = null
}

variable "availability_zone_rebalancing" {
  description = "(Optional) Whether to use Availability Zone rebalancing. Valid values are `ENABLED` and `DISABLED`."
  type        = string
  default     = null
}

variable "triggers" {
  description = "(Optional) Map of arbitrary keys and values that, when changed, will trigger an in-place update (forced new deployment)."
  type        = map(string)
  default     = {}
}

variable "ignore_desired_count" {
  description = "(Optional) When true, a lifecycle ignore_changes on `desired_count` is applied so external autoscaling does not fight Terraform. Defaults to false."
  type        = bool
  default     = false
}

###########################
# General Variables
###########################

variable "tags" {
  description = "(Optional) A map of tags to assign to the service and the security group created via composition. A `Name` tag is merged automatically."
  type        = map(string)
  default     = {}
}
