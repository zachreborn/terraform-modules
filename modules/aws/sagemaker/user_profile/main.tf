##############################
# Provider Configuration
##############################
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# SageMaker User Profile
##############################
resource "aws_sagemaker_user_profile" "this" {
  domain_id                      = var.domain_id
  user_profile_name              = var.user_profile_name
  single_sign_on_user_identifier = var.single_sign_on_user_identifier
  single_sign_on_user_value      = var.single_sign_on_user_value
  tags                           = merge(tomap({ Name = var.user_profile_name }), var.tags)

  dynamic "user_settings" {
    for_each = var.user_settings != null ? [var.user_settings] : []
    content {
      auto_mount_home_efs = user_settings.value.auto_mount_home_efs
      default_landing_uri = user_settings.value.default_landing_uri
      execution_role      = user_settings.value.execution_role
      security_groups     = user_settings.value.security_groups
      studio_web_portal   = user_settings.value.studio_web_portal
      dynamic "canvas_app_settings" {
        for_each = user_settings.value.canvas_app_settings != null ? [user_settings.value.canvas_app_settings] : []
        content {
          dynamic "direct_deploy_settings" {
            for_each = canvas_app_settings.value.direct_deploy_settings != null ? [canvas_app_settings.value.direct_deploy_settings] : []
            content {
              status = direct_deploy_settings.value.status
            }
          }
          dynamic "emr_serverless_settings" {
            for_each = canvas_app_settings.value.emr_serverless_settings != null ? [canvas_app_settings.value.emr_serverless_settings] : []
            content {
              execution_role_arn = emr_serverless_settings.value.execution_role_arn
              status             = emr_serverless_settings.value.status
            }
          }
          dynamic "generative_ai_settings" {
            for_each = canvas_app_settings.value.generative_ai_settings != null ? [canvas_app_settings.value.generative_ai_settings] : []
            content {
              amazon_bedrock_role_arn = generative_ai_settings.value.amazon_bedrock_role_arn
            }
          }
          dynamic "identity_provider_oauth_settings" {
            for_each = canvas_app_settings.value.identity_provider_oauth_settings != null ? canvas_app_settings.value.identity_provider_oauth_settings : []
            content {
              data_source_name = identity_provider_oauth_settings.value.data_source_name
              secret_arn       = identity_provider_oauth_settings.value.secret_arn
              status           = identity_provider_oauth_settings.value.status
            }
          }
          dynamic "kendra_settings" {
            for_each = canvas_app_settings.value.kendra_settings != null ? [canvas_app_settings.value.kendra_settings] : []
            content {
              status = kendra_settings.value.status
            }
          }
          dynamic "model_register_settings" {
            for_each = canvas_app_settings.value.model_register_settings != null ? [canvas_app_settings.value.model_register_settings] : []
            content {
              cross_account_model_register_role_arn = model_register_settings.value.cross_account_model_register_role_arn
              status                                = model_register_settings.value.status
            }
          }
          dynamic "time_series_forecasting_settings" {
            for_each = canvas_app_settings.value.time_series_forecasting_settings != null ? [canvas_app_settings.value.time_series_forecasting_settings] : []
            content {
              amazon_forecast_role_arn = time_series_forecasting_settings.value.amazon_forecast_role_arn
              status                   = time_series_forecasting_settings.value.status
            }
          }
          dynamic "workspace_settings" {
            for_each = canvas_app_settings.value.workspace_settings != null ? [canvas_app_settings.value.workspace_settings] : []
            content {
              s3_artifact_path = workspace_settings.value.s3_artifact_path
              s3_kms_key_id    = workspace_settings.value.s3_kms_key_id
            }
          }
        }
      }
      dynamic "code_editor_app_settings" {
        for_each = user_settings.value.code_editor_app_settings != null ? [user_settings.value.code_editor_app_settings] : []
        content {
          built_in_lifecycle_config_arn = code_editor_app_settings.value.built_in_lifecycle_config_arn
          lifecycle_config_arns         = code_editor_app_settings.value.lifecycle_config_arns
          dynamic "app_lifecycle_management" {
            for_each = code_editor_app_settings.value.app_lifecycle_management != null ? [code_editor_app_settings.value.app_lifecycle_management] : []
            content {
              dynamic "idle_settings" {
                for_each = app_lifecycle_management.value.idle_settings != null ? [app_lifecycle_management.value.idle_settings] : []
                content {
                  idle_timeout_in_minutes     = idle_settings.value.idle_timeout_in_minutes
                  lifecycle_management        = idle_settings.value.lifecycle_management
                  max_idle_timeout_in_minutes = idle_settings.value.max_idle_timeout_in_minutes
                  min_idle_timeout_in_minutes = idle_settings.value.min_idle_timeout_in_minutes
                }
              }
            }
          }
          dynamic "custom_image" {
            for_each = code_editor_app_settings.value.custom_image != null ? code_editor_app_settings.value.custom_image : []
            content {
              app_image_config_name = custom_image.value.app_image_config_name
              image_name            = custom_image.value.image_name
              image_version_number  = custom_image.value.image_version_number
            }
          }
          dynamic "default_resource_spec" {
            for_each = code_editor_app_settings.value.default_resource_spec != null ? [code_editor_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
      dynamic "custom_file_system_config" {
        for_each = user_settings.value.custom_file_system_config != null ? user_settings.value.custom_file_system_config : []
        content {
          dynamic "efs_file_system_config" {
            for_each = custom_file_system_config.value.efs_file_system_config != null ? custom_file_system_config.value.efs_file_system_config : []
            content {
              file_system_id   = efs_file_system_config.value.file_system_id
              file_system_path = efs_file_system_config.value.file_system_path
            }
          }
        }
      }
      dynamic "custom_posix_user_config" {
        for_each = user_settings.value.custom_posix_user_config != null ? [user_settings.value.custom_posix_user_config] : []
        content {
          gid = custom_posix_user_config.value.gid
          uid = custom_posix_user_config.value.uid
        }
      }
      dynamic "jupyter_lab_app_settings" {
        for_each = user_settings.value.jupyter_lab_app_settings != null ? [user_settings.value.jupyter_lab_app_settings] : []
        content {
          built_in_lifecycle_config_arn = jupyter_lab_app_settings.value.built_in_lifecycle_config_arn
          lifecycle_config_arns         = jupyter_lab_app_settings.value.lifecycle_config_arns
          dynamic "app_lifecycle_management" {
            for_each = jupyter_lab_app_settings.value.app_lifecycle_management != null ? [jupyter_lab_app_settings.value.app_lifecycle_management] : []
            content {
              dynamic "idle_settings" {
                for_each = app_lifecycle_management.value.idle_settings != null ? [app_lifecycle_management.value.idle_settings] : []
                content {
                  idle_timeout_in_minutes     = idle_settings.value.idle_timeout_in_minutes
                  lifecycle_management        = idle_settings.value.lifecycle_management
                  max_idle_timeout_in_minutes = idle_settings.value.max_idle_timeout_in_minutes
                  min_idle_timeout_in_minutes = idle_settings.value.min_idle_timeout_in_minutes
                }
              }
            }
          }
          dynamic "code_repository" {
            for_each = jupyter_lab_app_settings.value.code_repository != null ? jupyter_lab_app_settings.value.code_repository : []
            content {
              repository_url = code_repository.value.repository_url
            }
          }
          dynamic "custom_image" {
            for_each = jupyter_lab_app_settings.value.custom_image != null ? jupyter_lab_app_settings.value.custom_image : []
            content {
              app_image_config_name = custom_image.value.app_image_config_name
              image_name            = custom_image.value.image_name
              image_version_number  = custom_image.value.image_version_number
            }
          }
          dynamic "default_resource_spec" {
            for_each = jupyter_lab_app_settings.value.default_resource_spec != null ? [jupyter_lab_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
          dynamic "emr_settings" {
            for_each = jupyter_lab_app_settings.value.emr_settings != null ? [jupyter_lab_app_settings.value.emr_settings] : []
            content {
              assumable_role_arns = emr_settings.value.assumable_role_arns
              execution_role_arns = emr_settings.value.execution_role_arns
            }
          }
        }
      }
      dynamic "jupyter_server_app_settings" {
        for_each = user_settings.value.jupyter_server_app_settings != null ? [user_settings.value.jupyter_server_app_settings] : []
        content {
          lifecycle_config_arns = jupyter_server_app_settings.value.lifecycle_config_arns
          dynamic "code_repository" {
            for_each = jupyter_server_app_settings.value.code_repository != null ? jupyter_server_app_settings.value.code_repository : []
            content {
              repository_url = code_repository.value.repository_url
            }
          }
          dynamic "default_resource_spec" {
            for_each = jupyter_server_app_settings.value.default_resource_spec != null ? [jupyter_server_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
      dynamic "kernel_gateway_app_settings" {
        for_each = user_settings.value.kernel_gateway_app_settings != null ? [user_settings.value.kernel_gateway_app_settings] : []
        content {
          lifecycle_config_arns = kernel_gateway_app_settings.value.lifecycle_config_arns
          dynamic "custom_image" {
            for_each = kernel_gateway_app_settings.value.custom_image != null ? kernel_gateway_app_settings.value.custom_image : []
            content {
              app_image_config_name = custom_image.value.app_image_config_name
              image_name            = custom_image.value.image_name
              image_version_number  = custom_image.value.image_version_number
            }
          }
          dynamic "default_resource_spec" {
            for_each = kernel_gateway_app_settings.value.default_resource_spec != null ? [kernel_gateway_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
      dynamic "r_session_app_settings" {
        for_each = user_settings.value.r_session_app_settings != null ? [user_settings.value.r_session_app_settings] : []
        content {
          dynamic "custom_image" {
            for_each = r_session_app_settings.value.custom_image != null ? r_session_app_settings.value.custom_image : []
            content {
              app_image_config_name = custom_image.value.app_image_config_name
              image_name            = custom_image.value.image_name
              image_version_number  = custom_image.value.image_version_number
            }
          }
          dynamic "default_resource_spec" {
            for_each = r_session_app_settings.value.default_resource_spec != null ? [r_session_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
      dynamic "r_studio_server_pro_app_settings" {
        for_each = user_settings.value.r_studio_server_pro_app_settings != null ? [user_settings.value.r_studio_server_pro_app_settings] : []
        content {
          access_status = r_studio_server_pro_app_settings.value.access_status
          user_group    = r_studio_server_pro_app_settings.value.user_group
        }
      }
      dynamic "sharing_settings" {
        for_each = user_settings.value.sharing_settings != null ? [user_settings.value.sharing_settings] : []
        content {
          notebook_output_option = sharing_settings.value.notebook_output_option
          s3_kms_key_id          = sharing_settings.value.s3_kms_key_id
          s3_output_path         = sharing_settings.value.s3_output_path
        }
      }
      dynamic "space_storage_settings" {
        for_each = user_settings.value.space_storage_settings != null ? [user_settings.value.space_storage_settings] : []
        content {
          dynamic "default_ebs_storage_settings" {
            for_each = space_storage_settings.value.default_ebs_storage_settings != null ? [space_storage_settings.value.default_ebs_storage_settings] : []
            content {
              default_ebs_volume_size_in_gb = default_ebs_storage_settings.value.default_ebs_volume_size_in_gb
              maximum_ebs_volume_size_in_gb = default_ebs_storage_settings.value.maximum_ebs_volume_size_in_gb
            }
          }
        }
      }
      dynamic "studio_web_portal_settings" {
        for_each = user_settings.value.studio_web_portal_settings != null ? [user_settings.value.studio_web_portal_settings] : []
        content {
          hidden_app_types      = studio_web_portal_settings.value.hidden_app_types
          hidden_instance_types = studio_web_portal_settings.value.hidden_instance_types
          hidden_ml_tools       = studio_web_portal_settings.value.hidden_ml_tools
        }
      }
      dynamic "tensor_board_app_settings" {
        for_each = user_settings.value.tensor_board_app_settings != null ? [user_settings.value.tensor_board_app_settings] : []
        content {
          dynamic "default_resource_spec" {
            for_each = tensor_board_app_settings.value.default_resource_spec != null ? [tensor_board_app_settings.value.default_resource_spec] : []
            content {
              instance_type                 = default_resource_spec.value.instance_type
              lifecycle_config_arn          = default_resource_spec.value.lifecycle_config_arn
              sagemaker_image_arn           = default_resource_spec.value.sagemaker_image_arn
              sagemaker_image_version_alias = default_resource_spec.value.sagemaker_image_version_alias
              sagemaker_image_version_arn   = default_resource_spec.value.sagemaker_image_version_arn
            }
          }
        }
      }
    }
  }
}
