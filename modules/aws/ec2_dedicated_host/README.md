# AWS EC2 Dedicated Host Module

This module creates and manages an AWS EC2 Dedicated Host (`aws_ec2_host`). Dedicated Hosts are physical servers with EC2 instance capacity fully dedicated to your use.

Common use cases include Mac instances (`mac-m4.metal`, `mac2-m2.metal`, etc.) which require a dedicated host for licensing compliance.

## Usage

```hcl
module "mac_dedicated_host" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/ec2_dedicated_host?ref=dev_mac_dedicated_host"

  name              = "mac-m4-host-01"
  instance_type     = "mac-m4.metal"
  availability_zone = "us-west-2a"
  auto_placement    = "off"
  host_recovery     = "off"

  tags = {
    terraform   = "true"
    created_by  = "Jake Jones"
    environment = "prod"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 6.0.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| availability_zone | The Availability Zone in which to allocate the Dedicated Host | `string` | n/a | yes |
| instance_type | Instance type supported by the host (e.g. mac-m4.metal) | `string` | n/a | yes |
| name | Name tag to assign to the Dedicated Host | `string` | n/a | yes |
| auto_placement | Whether the host accepts untargeted launches. Valid: `on` or `off` | `string` | `"on"` | no |
| host_recovery | Enable host recovery. Valid: `on` or `off` | `string` | `"off"` | no |
| tags | Map of tags to assign to the resource | `map(string)` | `{ terraform = "true" }` | no |

## Outputs

| Name | Description |
|------|-------------|
| id | The ID of the Dedicated Host |
| arn | The ARN of the Dedicated Host |
| availability_zone | The Availability Zone of the Dedicated Host |
| instance_type | The instance type supported by the Dedicated Host |

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.0.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_ec2_host.host](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ec2_host) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_auto_placement"></a> [auto\_placement](#input\_auto\_placement) | (Optional) Indicates whether the host accepts any untargeted instance launches that match its instance type configuration, or if it only accepts Host tenancy instance launches that specify its unique host ID. Valid values: 'on' or 'off'. Default: 'on'. | `string` | `"on"` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | (Required) The Availability Zone in which to allocate the Dedicated Host. | `string` | n/a | yes |
| <a name="input_host_recovery"></a> [host\_recovery](#input\_host\_recovery) | (Optional) Indicates whether to enable or disable host recovery for the Dedicated Host. Valid values: 'on' or 'off'. Default: 'off'. | `string` | `"off"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | (Required) Specifies the instance type to be supported by the Dedicated Hosts. e.g. mac-m4.metal, mac2-m2.metal. | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | (Required) The name tag to assign to the Dedicated Host. | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A mapping of tags to assign to the resource. | `map(string)` | <pre>{<br/>  "terraform": "true"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arn"></a> [arn](#output\_arn) | The ARN of the Dedicated Host. |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | The Availability Zone of the Dedicated Host. |
| <a name="output_id"></a> [id](#output\_id) | The ID of the Dedicated Host. |
| <a name="output_instance_type"></a> [instance\_type](#output\_instance\_type) | The instance type supported by the Dedicated Host. |
<!-- END_TF_DOCS -->
<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://github.com/zachreborn)
- [Jake Jones](https://github.com/jakeasarus)
- [Brad Engberg](https://github.com/bradms98)
