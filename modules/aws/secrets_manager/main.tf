###########################
# Provider Configuration
###########################
terraform {
  # 1.11.0 is required for ephemeral variables and write-only resource arguments, which
  # this module uses to keep secret material out of state and plan files entirely. See the
  # "Write-Only Secret Values" section in README.md.
  required_version = ">= 1.11.0"
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

# Only needed to build the key policy for composed KMS keys. Gated with count so callers
# that don't set create_kms_key aren't forced into an sts:GetCallerIdentity call on every
# plan (which would otherwise fail closed in restricted or offline environments).
data "aws_caller_identity" "current" {
  count = length(local.kms_key_secrets) > 0 ? 1 : 0
}

###########################
# Locals
###########################

locals {
  # Secrets that need a module-composed customer managed KMS key.
  kms_key_secrets = { for k, v in var.secrets : k => v if v.create_kms_key }

  # Resolve the effective KMS key ID for each secret: the composed key's ARN when
  # create_kms_key is true, else the caller-supplied kms_key_id, else null (Secrets
  # Manager falls back to the AWS managed key aws/secretsmanager).
  resolved_kms_key_id = {
    for k, v in var.secrets : k => v.create_kms_key ? module.kms_key[k].arn : v.kms_key_id
  }

  # Instance keys (not values) for secret_values entries that have a corresponding var.secrets key.
  # The keys themselves are not sensitive, but var.secret_values is marked sensitive as a whole, so
  # nonsensitive() is required here to use them as a for_each set below -- the sensitive values are
  # still looked up per-instance from var.secret_values directly, never through this local.
  secret_value_keys = toset([for k in nonsensitive(keys(var.secret_values)) : k if contains(keys(var.secrets), k)])

  # Secrets with rotation enabled.
  rotation_secrets = { for k, v in var.secrets : k => v if v.enable_rotation }

  # Secrets with an independently managed resource policy.
  policy_secrets = { for k, v in var.secrets : k => v if v.manage_resource_policy }
}

###########################
# KMS Encryption Keys
###########################

module "kms_key" {
  source = "../kms"

  for_each = local.kms_key_secrets

  name_prefix         = "secretsmanager-${each.key}-"
  description         = "Customer managed KMS key used to encrypt the ${each.key} Secrets Manager secret."
  enable_key_rotation = true
  tags                = merge(var.tags, each.value.tags)

  # Delegates key management/usage entirely to IAM policies in this account, matching the
  # standard "Enable IAM User Permissions" statement AWS applies by default. A second
  # statement scoping this same root principal to Secrets Manager via a kms:ViaService
  # condition would be a no-op: KMS key policies are additive-only, so the unconditional
  # kms:* grant to root below already permits every action the conditional statement would
  # allow, and there is no implicit deny to narrow. To genuinely restrict a caller to using
  # this key only through Secrets Manager, add a kms:ViaService condition to that caller's
  # own IAM policy (see the Consuming Secrets Safely section in README.md), not to this key
  # policy's root statement.
  policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Sid"    = "EnableIAMUserPermissions",
        "Effect" = "Allow",
        "Principal" = {
          "AWS" = "arn:aws:iam::${data.aws_caller_identity.current[0].account_id}:root"
        },
        "Action"   = "kms:*",
        "Resource" = "*"
      }
    ]
  })
}

###########################
# Secrets Manager Secret
###########################

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                           = each.value.name_prefix == null ? coalesce(each.value.name, each.key) : null
  name_prefix                    = each.value.name_prefix
  description                    = each.value.description
  kms_key_id                     = local.resolved_kms_key_id[each.key]
  policy                         = each.value.policy
  recovery_window_in_days        = each.value.recovery_window_in_days
  force_overwrite_replica_secret = each.value.force_overwrite_replica_secret
  tags                           = merge(var.tags, each.value.tags)

  dynamic "replica" {
    for_each = each.value.replica
    content {
      region     = replica.value.region
      kms_key_id = replica.value.kms_key_id
    }
  }
}

###########################
# Secrets Manager Secret Version
###########################

resource "aws_secretsmanager_secret_version" "this" {
  for_each = local.secret_value_keys

  secret_id      = aws_secretsmanager_secret.this[each.key].id
  secret_string  = var.secret_values[each.key].secret_string
  secret_binary  = var.secret_values[each.key].secret_binary
  version_stages = var.secret_values[each.key].version_stages
}

###########################
# Secrets Manager Secret Version (Write-Only)
###########################

# Separate from the persisted version resource above because write-only arguments and
# ephemeral values cannot be mixed with normal ones on the same attribute set: an ephemeral
# value may only be assigned to a write-only argument, never to secret_string/secret_binary.
resource "aws_secretsmanager_secret_version" "wo" {
  # for_each is driven by the NON-ephemeral versions map, because ephemeral values cannot be
  # used in for_each. Its keys therefore select which secrets receive a write-only value.
  for_each = var.secret_values_wo_versions

  secret_id                = aws_secretsmanager_secret.this[each.key].id
  secret_string_wo         = var.secret_values_wo[each.key]
  secret_string_wo_version = each.value
}

###########################
# Secrets Manager Secret Rotation
###########################

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = local.rotation_secrets

  secret_id           = aws_secretsmanager_secret.this[each.key].id
  rotation_lambda_arn = each.value.rotation_lambda_arn
  rotate_immediately  = each.value.rotate_immediately

  rotation_rules {
    automatically_after_days = each.value.rotation_automatically_after_days
    duration                 = each.value.rotation_duration
    schedule_expression      = each.value.rotation_schedule_expression
  }
}

###########################
# Secrets Manager Secret Policy
###########################

resource "aws_secretsmanager_secret_policy" "this" {
  for_each = local.policy_secrets

  secret_arn          = aws_secretsmanager_secret.this[each.key].arn
  policy              = each.value.resource_policy
  block_public_policy = each.value.block_public_policy
}
