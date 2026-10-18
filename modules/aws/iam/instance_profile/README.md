# IAM instance profile

Manages exactly one `aws_iam_instance_profile` attached to an existing IAM role.
Module path: `modules/aws/iam/instance_profile`.

## Prerequisites

- OpenTofu 1.6.0+ or Terraform 1.2.0+, and AWS provider 6.0.0+.
- An existing IAM role that trusts `ec2.amazonaws.com` (or the relevant service).
  This module neither creates nor verifies the role or its trust policy.

## Usage

### Profile for a role created by the IAM role module

```hcl
module "my_role" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/role"

  name        = "application-ec2"
  policy_arns = []
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

module "instance_profile" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/instance_profile"

  name = "application-ec2"
  role = module.my_role.name
}
```

### Generated name

```hcl
module "prefixed_profile" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/instance_profile"

  name_prefix = "application-"
  role        = "existing-ec2-role"
}
```

### Custom path and tags

```hcl
module "service_profile" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/iam/instance_profile"

  name = "application-service"
  role = "existing-ec2-role"
  path = "/service-role/"
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## Notes and design decisions

- `role` requires a role **name**, not an ARN or `/path/role-name`. An ARN fails
  at plan time; `modules/aws/iam/role` exposes `name` for this purpose. To use a
  role identified by an ARN, supply its last path segment yourself.
- **This module does not configure Session Manager** and creates no
  `aws_ssm_document`. Use `modules/aws/session_manager` when you want Session
  Manager preferences. No roles, policies, policy attachments, or EC2
  attachments are created here.
- Exactly one of `name` or `name_prefix` must be set. Profile names must be unique
  within the account, regardless of path or attached role. Changing the name,
  prefix, or path forces replacement.
- `id` is the profile name, so it duplicates `name`. With `name_prefix`, the
  resolved `name` is assigned by the provider.
- The `Name` tag is merged only when `name` is set. It is omitted for
  `name_prefix` because the generated name is not known at configuration time.
  Caller tags override the merged `Name` tag.
- Tags default to `{ terraform = "true" }`. Supplying `tags` replaces that map,
  rather than merging it with the default. `tags_all` also exposes tags inherited
  from the AWS provider's `default_tags`.
- Each module call manages a single profile. Use `for_each` on the caller's
  module block to manage multiple profiles; there is no map or YAML input.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_name"></a> [name](#input\_name) | Name of the instance profile, unique within the account regardless of path or role. Forces replacement. Exactly one of name or name\_prefix is required. | `string` | `null` | no |
| <a name="input_name_prefix"></a> [name\_prefix](#input\_name\_prefix) | Prefix for a generated unique instance-profile name. Forces replacement. Exactly one of name or name\_prefix is required. | `string` | `null` | no |
| <a name="input_path"></a> [path](#input\_path) | Path to the instance profile, beginning and ending with / and at most 512 characters. Forces replacement. | `string` | `"/"` | no |
| <a name="input_role"></a> [role](#input\_role) | Name (not ARN or path) of an existing IAM role to attach. The role must trust EC2 or the relevant service; this module does not create or verify it. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the instance profile. A supplied map replaces the default; Name is merged when name is set, and caller tags take precedence. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | ARN assigned by AWS to the instance profile. |
| <a name="output_create_date"></a> [create\_date](#output\_create\_date) | Creation timestamp of the instance profile. |
| <a name="output_id"></a> [id](#output\_id) | Instance-profile ID, which equals its name. |
| <a name="output_name"></a> [name](#output\_name) | Resolved instance-profile name, including a name generated from name\_prefix. |
| <a name="output_path"></a> [path](#output\_path) | Applied instance-profile path. |
| <a name="output_role"></a> [role](#output\_role) | IAM role name attached to the instance profile. |
| <a name="output_tags_all"></a> [tags\_all](#output\_tags\_all) | All instance-profile tags, including inherited provider default\_tags. |
| <a name="output_unique_id"></a> [unique\_id](#output\_unique\_id) | AWS-assigned unique ID of the instance profile. |
<!-- END_TF_DOCS -->
