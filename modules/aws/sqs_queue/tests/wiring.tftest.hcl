mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com" }
  }
  mock_data "aws_region" {
    defaults = { region = "us-east-1" }
  }
  mock_resource "aws_kms_key" {
    defaults = {
      arn    = "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-4000-8000-000000000000"
      key_id = "00000000-0000-4000-8000-000000000000"
    }
  }
}

variables {
  name = "work"
}

run "legacy_created_key_defaults" {
  command = apply
  assert {
    condition     = length(module.kms) == 1 && module.kms[0].description == "CloudTrail kms key used to encrypt audit logs" && module.kms[0].deletion_window_in_days == 30 && module.kms[0].enable_key_rotation && module.kms[0].alias_name_prefix == "alias/sqs_key_"
    error_message = "Legacy key creation, description, deletion, rotation and alias defaults must reach the real child."
  }
  assert {
    condition     = output.kms_key_arn == "arn:aws:kms:us-east-1:123456789012:key/00000000-0000-4000-8000-000000000000" && output.kms_key_id == "00000000-0000-4000-8000-000000000000" && output.effective_kms_master_key_id == output.kms_key_arn && aws_sqs_queue.queue.kms_master_key_id == output.kms_key_arn && aws_sqs_queue.queue.kms_data_key_reuse_period_seconds == 300
    error_message = "Created key identifiers and queue KMS reference must match exactly."
  }
  assert {
    condition     = jsondecode(local.generated_key_policy).Statement[0].Principal.AWS == "arn:aws:iam::123456789012:root" && jsondecode(local.generated_key_policy).Statement[1].Condition.ArnLike["kms:EncryptionContext:aws:sqs:arn"] == "arn:aws:sqs:us-east-1:123456789012:work" && jsondecode(local.generated_key_policy).Statement[1].Condition.StringEquals == { "kms:CallerAccount" = "123456789012", "kms:ViaService" = "sqs.us-east-1.amazonaws.com" } && jsondecode(local.generated_key_policy).Statement[1].Action == ["kms:Decrypt", "kms:GenerateDataKey"]
    error_message = "Generated key policy must be cycle-free, queue/account/region-scoped with exact service actions."
  }
}

run "legacy_key_overrides" {
  command = apply
  variables {
    key_description              = "Queue encryption"
    key_deletion_window_in_days  = 7
    key_enable_key_rotation      = false
    key_is_enabled               = false
    key_usage                    = "ENCRYPT_DECRYPT"
    key_customer_master_key_spec = "SYMMETRIC_DEFAULT"
    key_name_prefix              = "alias/work_"
    key_policy                   = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { AWS = "arn:aws:iam::123456789012:root" }, Action = "kms:*", Resource = "*" }] })
    region                       = "us-west-2"
    tags                         = { Name = "caller" }
  }
  assert {
    condition     = module.kms[0].description == "Queue encryption" && module.kms[0].deletion_window_in_days == 7 && !module.kms[0].enable_key_rotation && module.kms[0].alias_name_prefix == "alias/work_" && length(data.aws_caller_identity.current) == 0 && length(data.aws_partition.current) == 0 && length(data.aws_region.current) == 0 && local.generated_key_policy == null
    error_message = "Legacy overrides must reach the child and explicit policy must skip all generation lookups."
  }
}

run "partition_and_region_override" {
  command = plan
  override_data {
    target = data.aws_partition.current[0]
    values = { partition = "aws-cn", dns_suffix = "amazonaws.com.cn" }
  }
  variables {
    region = "cn-north-1"
  }
  assert {
    condition     = jsondecode(local.generated_key_policy).Statement[0].Principal.AWS == "arn:aws-cn:iam::123456789012:root" && jsondecode(local.generated_key_policy).Statement[1].Condition.ArnLike["kms:EncryptionContext:aws:sqs:arn"] == "arn:aws-cn:sqs:cn-north-1:123456789012:work" && jsondecode(local.generated_key_policy).Statement[1].Condition.StringEquals["kms:ViaService"] == "sqs.cn-north-1.amazonaws.com" && length(data.aws_region.current) == 0
    error_message = "Explicit region and partition must control policy ARN/principal/service without a provider-region lookup."
  }
}

run "generated_key_prefix_policy" {
  command = plan
  variables {
    name        = null
    name_prefix = "work-"
  }
  assert {
    condition     = jsondecode(local.generated_key_policy).Statement[1].Condition.ArnLike["kms:EncryptionContext:aws:sqs:arn"] == "arn:aws:sqs:us-east-1:123456789012:work-*"
    error_message = "Generated names must use a prefix-scoped policy without a queue dependency."
  }
}

run "generated_key_no_prefix_policy" {
  command = plan
  variables {
    name = null
  }
  assert {
    condition     = jsondecode(local.generated_key_policy).Statement[1].Condition.ArnLike["kms:EncryptionContext:aws:sqs:arn"] == "arn:aws:sqs:us-east-1:123456789012:*"
    error_message = "Fully generated naming must retain account/region scope without a resource dependency."
  }
}

run "external_key_arn" {
  command = plan
  variables {
    create_kms_key    = false
    kms_master_key_id = "arn:aws:kms:us-east-1:123456789012:key/11111111-1111-4111-8111-111111111111"
  }
  assert {
    condition     = length(module.kms) == 0 && aws_sqs_queue.queue.kms_master_key_id == "arn:aws:kms:us-east-1:123456789012:key/11111111-1111-4111-8111-111111111111" && output.effective_kms_master_key_id == aws_sqs_queue.queue.kms_master_key_id && output.kms_key_arn == null && output.kms_key_id == null && aws_sqs_queue.queue.kms_data_key_reuse_period_seconds == 300
    error_message = "External ARN must be forwarded exactly without claiming a created key."
  }
}

run "external_key_id" {
  command = plan
  variables {
    create_kms_key                    = false
    kms_master_key_id                 = "11111111-1111-4111-8111-111111111111"
    kms_data_key_reuse_period_seconds = 86400
  }
  assert {
    condition     = length(module.kms) == 0 && aws_sqs_queue.queue.kms_master_key_id == "11111111-1111-4111-8111-111111111111" && output.effective_kms_master_key_id == "11111111-1111-4111-8111-111111111111" && output.kms_key_arn == null && output.kms_key_id == null && aws_sqs_queue.queue.kms_data_key_reuse_period_seconds == 86400
    error_message = "External ID and reuse override must be preserved."
  }
}

run "external_key_alias" {
  command = plan
  variables {
    create_kms_key    = false
    kms_master_key_id = "alias/aws/sqs"
  }
  assert {
    condition     = length(module.kms) == 0 && aws_sqs_queue.queue.kms_master_key_id == "alias/aws/sqs" && output.effective_kms_master_key_id == "alias/aws/sqs" && output.kms_key_arn == null && output.kms_key_id == null
    error_message = "Alias must not be misrepresented as a resolved key ARN."
  }
}
