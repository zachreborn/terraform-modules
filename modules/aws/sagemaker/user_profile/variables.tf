###########################
# User Profile Variables
###########################

variable "domain_id" {
  type        = string
  description = "(Required) The ID of the associated SageMaker domain."
}

variable "user_profile_name" {
  type        = string
  description = "(Required) The name for the user profile."
}

variable "single_sign_on_user_identifier" {
  type        = string
  description = "(Optional) A specifier for the type of value specified in single_sign_on_user_value. Only valid when the domain auth_mode is SSO. The only supported value is UserName. If the domain auth_mode is IAM, this field is disallowed."
  default     = null
  validation {
    condition     = var.single_sign_on_user_identifier == null ? true : var.single_sign_on_user_identifier == "UserName"
    error_message = "single_sign_on_user_identifier must be UserName or null."
  }
}

variable "single_sign_on_user_value" {
  type        = string
  description = "(Optional) The username of the associated AWS Single Sign-On user for this user profile. Required when the domain auth_mode is SSO, and must be null when the domain auth_mode is IAM."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Map of tags to assign to the resource."
  default     = {}
}

###########################
# Nested Block Variables
###########################

variable "user_settings" {
  type = object({
    auto_mount_home_efs = optional(string)
    default_landing_uri = optional(string)
    execution_role      = string
    security_groups     = optional(list(string))
    studio_web_portal   = optional(string)
    canvas_app_settings = optional(object({
      direct_deploy_settings = optional(object({
        status = optional(string)
      }))
      emr_serverless_settings = optional(object({
        execution_role_arn = optional(string)
        status             = optional(string)
      }))
      generative_ai_settings = optional(object({
        amazon_bedrock_role_arn = optional(string)
      }))
      identity_provider_oauth_settings = optional(list(object({
        data_source_name = optional(string)
        secret_arn       = string
        status           = optional(string)
      })))
      kendra_settings = optional(object({
        status = optional(string)
      }))
      model_register_settings = optional(object({
        cross_account_model_register_role_arn = optional(string)
        status                                = optional(string)
      }))
      time_series_forecasting_settings = optional(object({
        amazon_forecast_role_arn = optional(string)
        status                   = optional(string)
      }))
      workspace_settings = optional(object({
        s3_artifact_path = optional(string)
        s3_kms_key_id    = optional(string)
      }))
    }))
    code_editor_app_settings = optional(object({
      built_in_lifecycle_config_arn = optional(string)
      lifecycle_config_arns         = optional(list(string))
      app_lifecycle_management = optional(object({
        idle_settings = optional(object({
          idle_timeout_in_minutes     = optional(number)
          lifecycle_management        = optional(string)
          max_idle_timeout_in_minutes = optional(number)
          min_idle_timeout_in_minutes = optional(number)
        }))
      }))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    custom_file_system_config = optional(list(object({
      efs_file_system_config = optional(list(object({
        file_system_id   = string
        file_system_path = optional(string)
      })))
    })))
    custom_posix_user_config = optional(object({
      gid = number
      uid = number
    }))
    jupyter_lab_app_settings = optional(object({
      built_in_lifecycle_config_arn = optional(string)
      lifecycle_config_arns         = optional(list(string))
      app_lifecycle_management = optional(object({
        idle_settings = optional(object({
          idle_timeout_in_minutes     = optional(number)
          lifecycle_management        = optional(string)
          max_idle_timeout_in_minutes = optional(number)
          min_idle_timeout_in_minutes = optional(number)
        }))
      }))
      code_repository = optional(list(object({
        repository_url = string
      })))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
      emr_settings = optional(object({
        assumable_role_arns = optional(list(string))
        execution_role_arns = optional(list(string))
      }))
    }))
    jupyter_server_app_settings = optional(object({
      lifecycle_config_arns = optional(list(string))
      code_repository = optional(list(object({
        repository_url = string
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    kernel_gateway_app_settings = optional(object({
      lifecycle_config_arns = optional(list(string))
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    r_session_app_settings = optional(object({
      custom_image = optional(list(object({
        app_image_config_name = string
        image_name            = string
        image_version_number  = optional(number)
      })))
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
    r_studio_server_pro_app_settings = optional(object({
      access_status = optional(string)
      user_group    = optional(string)
    }))
    sharing_settings = optional(object({
      notebook_output_option = optional(string)
      s3_kms_key_id          = optional(string)
      s3_output_path         = optional(string)
    }))
    space_storage_settings = optional(object({
      default_ebs_storage_settings = optional(object({
        default_ebs_volume_size_in_gb = number
        maximum_ebs_volume_size_in_gb = number
      }))
    }))
    studio_web_portal_settings = optional(object({
      hidden_app_types      = optional(list(string))
      hidden_instance_types = optional(list(string))
      hidden_ml_tools       = optional(list(string))
    }))
    tensor_board_app_settings = optional(object({
      default_resource_spec = optional(object({
        instance_type                 = optional(string)
        lifecycle_config_arn          = optional(string)
        sagemaker_image_arn           = optional(string)
        sagemaker_image_version_alias = optional(string)
        sagemaker_image_version_arn   = optional(string)
      }))
    }))
  })
  description = "(Optional) The user settings applied to the user profile. Must include execution_role when set; all app-settings sub-blocks are optional and map directly to the aws_sagemaker_user_profile user_settings block."
  default     = null
}
