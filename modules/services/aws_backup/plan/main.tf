resource "aws_backup_plan" "this" {
  provider = aws.aws_prod_region
  name     = var.name
  tags     = var.tags

  dynamic "rule" {
    for_each = var.rules
    content {
      rule_name                = rule.value.rule_name
      target_vault_name        = rule.value.target_vault_name
      schedule                 = rule.value.schedule
      enable_continuous_backup = rule.value.enable_continuous_backup
      start_window             = rule.value.start_window
      completion_window        = rule.value.completion_window
      lifecycle {
        delete_after = rule.value.delete_after
      }
    }
  }
}

resource "aws_backup_selection" "this" {
  provider      = aws.aws_prod_region
  iam_role_arn  = var.iam_role_arn
  name          = var.selection_name
  plan_id       = aws_backup_plan.this.id
  resources     = var.resources
  not_resources = var.not_resources
}

