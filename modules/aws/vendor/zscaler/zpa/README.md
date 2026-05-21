<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![MIT License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">Zscaler ZPA App Connector</h3>
  <p align="center">
    Deploys one or more Zscaler ZPA App Connector EC2 instances into private subnets, registers them with the Zscaler cloud using a provisioning key, and attaches an egress-only security group.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://zacharyhill.co">Zachary Hill</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Report Bug</a>
    ·
    <a href="https://github.com/zachreborn/terraform-modules/issues">Request Feature</a>
  </p>
</div>

<!-- TABLE OF CONTENTS -->
<details>
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#requirements">Requirements</a></li>
    <li><a href="#providers">Providers</a></li>
    <li><a href="#modules">Modules</a></li>
    <li><a href="#Resources">Resources</a></li>
    <li><a href="#inputs">Inputs</a></li>
    <li><a href="#outputs">Outputs</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
    <li><a href="#acknowledgments">Acknowledgments</a></li>
  </ol>
</details>

## Usage

### Production Deployment — 3 connectors across 3 AZs

Deploy three ZPA App Connectors in private subnets, one per availability zone, with static IPs and SSM access. Note that launching these instances does **not** route any traffic — you must assign Application Segments to the connector group in the ZPA admin portal to enable private access.

```hcl
module "zpa_connectors" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/vendor/zscaler/zpa?ref=v8.13.0"

  vpc_id               = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnet_ids
  private_ips          = ["10.200.0.8", "10.200.0.18", "10.200.0.38"]
  instance_name_prefix = "ZPAVP"
  instance_type        = "m7i-flex.large"
  iam_instance_profile = "ssm-role"
  provisioning_key     = var.zpa_provisioning_key

  tags = {
    created_by  = "terraform"
    environment = "prod"
    role        = "zpa_connector"
    terraform   = "true"
  }
}
```

### Prerequisites

Before running `terraform apply`:

1. Create a new **App Connector Group** in the ZPA admin portal dedicated to these AWS connectors.
2. Generate a **provisioning key** for that group.
3. Store the provisioning key as a **sensitive workspace variable** (`zpa_provisioning_key`).
4. Confirm outbound internet access from the target private subnets (Zscaler requires TCP 443 outbound to Zscaler cloud).

### Cutover to Production

After connectors register and show **Connected** in the ZPA admin portal:

1. Create or update **Application Segments** to use the new connector group.
2. Verify **Access Policies** reference those segments.
3. Test client connectivity to at least one private application before full cutover.

_For more examples, please refer to the [Documentation](https://github.com/zachreborn/terraform-modules)_

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs output will be input automatically below-->
<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
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
| [aws_cloudwatch_metric_alarm.instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_cloudwatch_metric_alarm.system](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_metric_alarm) | resource |
| [aws_instance.zpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_security_group.zpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.zpa_connector](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | (Optional) AMI ID to override the Zscaler Marketplace AMI. If not specified, the latest Zscaler App Connector AMI is selected automatically via the AWS Marketplace product code. | `string` | `null` | no |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | (Optional) Whether to encrypt the root EBS volume. Defaults to true. | `bool` | `true` | no |
| <a name="input_http_endpoint"></a> [http\_endpoint](#input\_http\_endpoint) | (Optional) Whether the instance metadata service is available. Valid values: enabled, disabled. Defaults to enabled. | `string` | `"enabled"` | no |
| <a name="input_http_tokens"></a> [http\_tokens](#input\_http\_tokens) | (Optional) Whether IMDSv2 session tokens are required. Valid values: optional, required. Defaults to optional to match Zscaler Marketplace AMI default. | `string` | `"optional"` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | (Optional) IAM instance profile name to attach to the ZPA App Connector instances for SSM access. | `string` | `null` | no |
| <a name="input_instance_name_prefix"></a> [instance\_name\_prefix](#input\_instance\_name\_prefix) | (Optional) Prefix used to generate the Name tag for each connector instance. A zero-padded two-digit index is appended (e.g., 'ZPAVP' → 'ZPAVP01', 'ZPAVP02', 'ZPAVP03'). | `string` | `"ZPAVP"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | (Optional) EC2 instance type for ZPA App Connector instances. Defaults to m5a.xlarge per Zscaler's official module recommendation. | `string` | `"m7i.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | (Optional) EC2 Key Pair name to associate with the instances for emergency console access. SSM access is preferred. | `string` | `null` | no |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | (Optional) Enable detailed CloudWatch monitoring on the instances. Defaults to true. | `bool` | `true` | no |
| <a name="input_private_ips"></a> [private\_ips](#input\_private\_ips) | (Optional) List of static private IP addresses to assign to each connector, one per subnet. Must be provided in the same order as subnet\_ids. If null, AWS assigns IPs automatically. | `list(string)` | `null` | no |
| <a name="input_provisioning_key"></a> [provisioning\_key](#input\_provisioning\_key) | (Required) ZPA App Connector provisioning key from the ZPA admin portal. This key registers the connectors to a specific App Connector Group. Mark as sensitive in the calling workspace. Connectors will NOT carry production traffic until Application Segments are assigned to the group in the ZPA admin portal. | `string` | n/a | yes |
| <a name="input_root_delete_on_termination"></a> [root\_delete\_on\_termination](#input\_root\_delete\_on\_termination) | (Optional) Whether to delete the root EBS volume when the instance is terminated. Defaults to true. | `bool` | `true` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | (Optional) Root EBS volume size in GiB. Minimum 64 GiB required by the Zscaler Marketplace AMI snapshot. | `number` | `75` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | (Optional) Root EBS volume type. Valid values: standard, gp2, gp3, io1, io2, sc1, st1. Defaults to gp3. | `string` | `"gp3"` | no |
| <a name="input_sg_name"></a> [sg\_name](#input\_sg\_name) | (Optional) Name for the ZPA App Connector security group. | `string` | `"zpa_connector_sg"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Required) List of private subnet IDs in which to launch one connector per subnet. The number of subnets determines the number of connector instances created. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags to assign to all resources created by this module. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "role": "zpa_connector",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (Required, Forces new resource) VPC ID in which to create the ZPA App Connector instances and security group. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_arns"></a> [arns](#output\_arns) | List of ARNs for the ZPA App Connector EC2 instances. |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | List of EC2 instance IDs for the ZPA App Connector instances. |
| <a name="output_private_ips"></a> [private\_ips](#output\_private\_ips) | List of private IP addresses assigned to the ZPA App Connector instances. |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the ZPA App Connector security group. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the ZPA App Connector security group. |
<!-- END_TF_DOCS -->

<!-- LICENSE -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- CONTACT -->

## Contact

Zachary Hill - [![LinkedIn][linkedin-shield]][linkedin-url] - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- ACKNOWLEDGMENTS -->

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/zachreborn/terraform-modules.svg?style=for-the-badge
[contributors-url]: https://github.com/zachreborn/terraform-modules/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/zachreborn/terraform-modules.svg?style=for-the-badge
[forks-url]: https://github.com/zachreborn/terraform-modules/network/members
[stars-shield]: https://img.shields.io/github/stars/zachreborn/terraform-modules.svg?style=for-the-badge
[stars-url]: https://github.com/zachreborn/terraform-modules/stargazers
[issues-shield]: https://img.shields.io/github/issues/zachreborn/terraform-modules.svg?style=for-the-badge
[issues-url]: https://github.com/zachreborn/terraform-modules/issues
[license-shield]: https://img.shields.io/github/license/zachreborn/terraform-modules.svg?style=for-the-badge
[license-url]: https://github.com/zachreborn/terraform-modules/blob/master/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/zachary-hill-5524257a/
[product-screenshot]: /images/screenshot.webp
[Terraform.io]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform
[Terraform-url]: https://terraform.io
