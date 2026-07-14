# No tests are possible for this module yet: it does not compile.
#
# `variables.tf` and `outputs.tf` are both empty, yet `main.tf` references many undeclared
# input variables (destination_policy_access_policy, iam_policy_description,
# iam_policy_name_prefix, iam_policy_path, tags, iam_role_assume_role_policy,
# iam_role_description, iam_role_force_detach_policies, iam_role_max_session_duration,
# iam_role_name_prefix, iam_role_permissions_boundary, destination_name,
# destination_target_arn) and two undeclared resources (aws_s3_bucket.firehose_bucket and
# aws_iam_role.iam_for_cloudwatch -- the latter is likely meant to be aws_iam_role.firehose_role).
#
# `tofu init -backend=false && tofu validate` fails outright with "Reference to undeclared
# resource" / "Reference to undeclared input variable" errors before a single `run` block
# could ever be evaluated, so no test could be authored here without editing main.tf /
# variables.tf, which is out of scope for test-authoring work.
#
# Tracked in: https://github.com/zachreborn/terraform-modules/issues/388
#
# Once that issue is fixed (variables.tf is completed and the dangling resource references
# are corrected), replace this file with real coverage following the pattern used in
# modules/aws/cloudwatch/log_group/tests/ and modules/aws/cloudwatch/event/tests/:
#   - mock_provider "aws" {}
#   - a valid-baseline `plan` run
#   - one run per validation {} failure mode added to variables.tf
#   - output assertions
