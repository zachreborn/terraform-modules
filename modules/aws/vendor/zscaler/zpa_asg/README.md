<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<br />
<div align="center">
  <a href="https://github.com/zachreborn/terraform-modules">
    <img src="/images/terraform_modules_logo.webp" alt="Logo" width="500" height="500">
  </a>

<h3 align="center">ZPA App Connector ASG (RHEL 9)</h3>
  <p align="center">
    Auto Scaling Group + Launch Template for Zscaler ZPA App Connectors on the Marketplace RHEL 9 AMI.
    <br />
    <a href="https://github.com/zachreborn/terraform-modules"><strong>Explore the docs »</strong></a>
  </p>
</div>

## Usage

### One connector per AZ (fixed capacity, oldest LT/instance dies first)

```hcl
module "zpa_connectors_asg" {
  source = "github.com/zachreborn/terraform-modules//modules/aws/vendor/zscaler/zpa_asg"

  name                      = "zpa-connectors"
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnet_ids
  iam_instance_profile      = "ssm-role"
  key_name                  = module.zpa_keypair.key_name
  provisioning_key          = var.zpa_provisioning_key
  instance_name_prefix      = "AWSZPAVPR"
  instance_type             = "m7i.large"
  min_size                  = 3
  desired_capacity          = 3
  max_size                  = 4
  max_instance_lifetime     = 7776000 # 90 days
  termination_policies      = ["OldestLaunchTemplate", "OldestInstance"]
  enable_ssm_agent          = true
  enable_host_os_update     = true
  # Marketplace AMI is pre-encrypted by Zscaler; AWS rejects re-encryption
  encrypted                 = false
  health_check_grace_period = 1200

  tags = {
    created_by  = "Jake Jones"
    environment = "prod"
    os          = "rhel9"
    role        = "zpa_connector"
    terraform   = "true"
  }
}
```

### Notes

- **Enrollment:** same App Connector Group provisioning key can enroll many ASG instances. Clean up stale connectors in the ZPA portal after replace/scale-in.
- **Host OS:** Zscaler docs use `yum` on RHEL; first-boot `yum update` is optional via `enable_host_os_update`.
- **SSM:** Marketplace AMI usually lacks amazon-ssm-agent; module installs it when `enable_ssm_agent=true`. Private subnets still need SSM VPC endpoints or working egress to AWS APIs.
- **source_dest_check:** disabled in user_data via `ec2:ModifyInstanceAttribute` (instance profile needs that permission).
- **Rolling replace:** publish a new LT version and run an ASG instance refresh. Termination policies prefer outdated LT then oldest instance.
- **IPs:** ASG assigns dynamic private IPs (not static).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- terraform-docs markdown table --output-file README.md --output-mode inject .-->
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.0.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_autoscaling_group.zpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.cpu_target](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_launch_template.zpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.zpa](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.zpa_connector_el9](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | (Optional) AMI ID override for the ZPA App Connector. When null, the latest Marketplace zpa-connector-el9* AMI is selected. | `string` | `null` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | (Optional) Associate a public IP. Defaults to false. | `bool` | `false` | no |
| <a name="input_capacity_rebalance"></a> [capacity\_rebalance](#input\_capacity\_rebalance) | (Optional) Enable capacity rebalance. Defaults to false. | `bool` | `false` | no |
| <a name="input_cpu_target_value"></a> [cpu\_target\_value](#input\_cpu\_target\_value) | (Optional) Target average CPU percent when enable\_cpu\_target\_tracking is true. | `number` | `50` | no |
| <a name="input_default_cooldown"></a> [default\_cooldown](#input\_default\_cooldown) | (Optional) ASG default cooldown in seconds. Defaults to 300. | `number` | `300` | no |
| <a name="input_desired_capacity"></a> [desired\_capacity](#input\_desired\_capacity) | (Optional) Desired number of connectors. Defaults to 3. | `number` | `3` | no |
| <a name="input_enable_cpu_target_tracking"></a> [enable\_cpu\_target\_tracking](#input\_enable\_cpu\_target\_tracking) | (Optional) Attach a CPU target-tracking scaling policy. Defaults to false. | `bool` | `false` | no |
| <a name="input_enable_host_os_update"></a> [enable\_host\_os\_update](#input\_enable\_host\_os\_update) | (Optional) Run yum update -y on first boot per Zscaler host OS guidance, then reboot. Defaults to true. | `bool` | `true` | no |
| <a name="input_enable_ssm_agent"></a> [enable\_ssm\_agent](#input\_enable\_ssm\_agent) | (Optional) Install and enable amazon-ssm-agent on first boot. Defaults to true. | `bool` | `true` | no |
| <a name="input_enabled_metrics"></a> [enabled\_metrics](#input\_enabled\_metrics) | (Optional) List of ASG group metrics to enable. | `list(string)` | `[]` | no |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | (Optional) Encrypt the root EBS volume. Defaults to false because Zscaler Marketplace AMIs are pre-encrypted and AWS may reject re-encryption. | `bool` | `false` | no |
| <a name="input_health_check_grace_period"></a> [health\_check\_grace\_period](#input\_health\_check\_grace\_period) | (Optional) Seconds after launch before health checks. Defaults to 1200 (20 minutes). | `number` | `1200` | no |
| <a name="input_health_check_type"></a> [health\_check\_type](#input\_health\_check\_type) | (Optional) ASG health check type. Defaults to EC2. | `string` | `"EC2"` | no |
| <a name="input_http_endpoint"></a> [http\_endpoint](#input\_http\_endpoint) | (Optional) Instance metadata service. Valid values: enabled, disabled. | `string` | `"enabled"` | no |
| <a name="input_http_put_response_hop_limit"></a> [http\_put\_response\_hop\_limit](#input\_http\_put\_response\_hop\_limit) | (Optional) IMDSv2 hop limit. Defaults to 2. | `number` | `2` | no |
| <a name="input_http_tokens"></a> [http\_tokens](#input\_http\_tokens) | (Optional) IMDSv2 token requirement. Defaults to required. | `string` | `"required"` | no |
| <a name="input_iam_instance_profile"></a> [iam\_instance\_profile](#input\_iam\_instance\_profile) | (Required) IAM instance profile name for SSM and instance permissions (e.g. ssm-role). | `string` | n/a | yes |
| <a name="input_instance_metadata_tags"></a> [instance\_metadata\_tags](#input\_instance\_metadata\_tags) | (Optional) Expose instance tags via metadata. Defaults to enabled. | `string` | `"enabled"` | no |
| <a name="input_instance_name_prefix"></a> [instance\_name\_prefix](#input\_instance\_name\_prefix) | (Optional) Name tag applied to instances launched by the ASG. | `string` | `"AWSZPAVPR"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | (Optional) EC2 instance type. Defaults to m7i.large. Marketplace RHEL AMIs do not support flex variants. | `string` | `"m7i.large"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | (Optional) EC2 Key Pair name for emergency console access. SSM is preferred. | `string` | `null` | no |
| <a name="input_max_instance_lifetime"></a> [max\_instance\_lifetime](#input\_max\_instance\_lifetime) | (Optional) Maximum instance lifetime in seconds. Defaults to 7776000 (90 days). Use 0 to disable. | `number` | `7776000` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | (Optional) Maximum number of connectors. Defaults to 4 for one extra during rolling replace. | `number` | `4` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | (Optional) Minimum number of connectors. Defaults to 3. | `number` | `3` | no |
| <a name="input_monitoring"></a> [monitoring](#input\_monitoring) | (Optional) Enable detailed CloudWatch monitoring. Defaults to false. | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | (Required) Base name for the Auto Scaling group and launch template prefix. | `string` | n/a | yes |
| <a name="input_provisioning_key"></a> [provisioning\_key](#input\_provisioning\_key) | (Required) ZPA App Connector provisioning key from the ZPA admin portal. Mark sensitive in the calling workspace. | `string` | n/a | yes |
| <a name="input_root_delete_on_termination"></a> [root\_delete\_on\_termination](#input\_root\_delete\_on\_termination) | (Optional) Delete root volume on termination. Defaults to true. | `bool` | `true` | no |
| <a name="input_root_device_name"></a> [root\_device\_name](#input\_root\_device\_name) | (Optional) Root device name for the block device mapping. | `string` | `"/dev/sda1"` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | (Optional) Root EBS volume size in GiB. Minimum 64 GiB required by the Zscaler Marketplace AMI. | `number` | `75` | no |
| <a name="input_root_volume_type"></a> [root\_volume\_type](#input\_root\_volume\_type) | (Optional) Root EBS volume type. Defaults to gp3. | `string` | `"gp3"` | no |
| <a name="input_sg_name"></a> [sg\_name](#input\_sg\_name) | (Optional) Name for the ZPA App Connector security group. | `string` | `"zpa_connector_asg_sg"` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Required) Private subnet IDs spanning AZs. For one connector per AZ set desired\_capacity equal to length(subnet\_ids). | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Map of tags assigned to resources created by this module. | `map(string)` | `{}` | no |
| <a name="input_termination_policies"></a> [termination\_policies](#input\_termination\_policies) | (Optional) Ordered termination policies. Defaults to OldestLaunchTemplate then OldestInstance. | `list(string)` | <pre>[<br/>  "OldestLaunchTemplate",<br/>  "OldestInstance"<br/>]</pre> | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | (Required, Forces new resource) VPC ID for the connector security group. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_ami_id"></a> [ami\_id](#output\_ami\_id) | AMI ID used by the launch template (resolved Marketplace el9 or override). |
| <a name="output_asg_arn"></a> [asg\_arn](#output\_asg\_arn) | ARN of the ZPA App Connector Auto Scaling group. |
| <a name="output_asg_desired_capacity"></a> [asg\_desired\_capacity](#output\_asg\_desired\_capacity) | Desired capacity of the Auto Scaling group. |
| <a name="output_asg_max_size"></a> [asg\_max\_size](#output\_asg\_max\_size) | Maximum size of the Auto Scaling group. |
| <a name="output_asg_min_size"></a> [asg\_min\_size](#output\_asg\_min\_size) | Minimum size of the Auto Scaling group. |
| <a name="output_asg_name"></a> [asg\_name](#output\_asg\_name) | Name of the ZPA App Connector Auto Scaling group. |
| <a name="output_launch_template_arn"></a> [launch\_template\_arn](#output\_launch\_template\_arn) | ARN of the ZPA App Connector launch template. |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | ID of the ZPA App Connector launch template. |
| <a name="output_launch_template_latest_version"></a> [launch\_template\_latest\_version](#output\_launch\_template\_latest\_version) | Latest version number of the launch template. |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the ZPA App Connector security group. |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | ID of the ZPA App Connector security group. |
<!-- END_TF_DOCS -->

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## Contact

Zachary Hill - zhill@zacharyhill.co

Project Link: [https://github.com/zachreborn/terraform-modules](https://github.com/zachreborn/terraform-modules)

## Acknowledgments

- [Zachary Hill](https://zacharyhill.co)
- [Jake Jones](https://github.com/jakeasarus)
