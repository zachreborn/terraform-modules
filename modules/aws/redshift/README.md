<!-- Blank module readme template: Do a search and replace with your text editor for the following: `module_name`, `module_description` -->
<!-- Improved compatibility of back to top link: See: https://github.com/othneildrew/Best-README-Template/pull/73 -->

<a name="readme-top"></a>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->

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

<h3 align="center">Load Balancer</h3>
  <p align="center">
    This module creates AWS Network and Application Load Balancers.
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

<!-- USAGE EXAMPLES -->

## Usage

### Redshift Cluster

module "redshift_prod_cluster" {
source = "github.com/zachreborn/terraform-modules//modules/aws/redshift"

cluster_identifier = "prod-datawarehouse"
node_type = "ra3.4xlarge"
cluster_type = "multi-node"
number_of_nodes = 4

database_name = "datawarehouse"
master_username = "prodadmin"
manage_master_password = true # AWS Secrets Manager manages password

vpc_security_group_ids = [aws_security_group.redshift.id]
cluster_subnet_group_name = aws_redshift_subnet_group.prod.name

publicly_accessible = false # Secure default
encrypted = true # Secure default
enhanced_vpc_routing = true # Secure default

automated_snapshot_retention_period = 14
skip_final_snapshot = false

tags = {
Environment = "production"
Project = "datawarehouse"
}
}

```

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
| [aws_redshift_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_cluster) | resource |
| [aws_redshift_cluster_iam_roles.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_cluster_iam_roles) | resource |
| [aws_redshift_parameter_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_parameter_group) | resource |
| [aws_redshift_snapshot_schedule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_snapshot_schedule) | resource |
| [aws_redshift_snapshot_schedule_association.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_snapshot_schedule_association) | resource |
| [aws_redshift_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_subnet_group) | resource |
| [aws_redshift_usage_limit.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/redshift_usage_limit) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_version_upgrade"></a> [allow\_version\_upgrade](#input\_allow\_version\_upgrade) | (Optional) If true, major version upgrades can be applied during the maintenance window to the Amazon Redshift engine. | `bool` | `true` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | (Optional) Specifies whether any cluster modifications are applied immediately, or during the next maintenance window. | `bool` | `false` | no |
| <a name="input_automated_snapshot_retention_period"></a> [automated\_snapshot\_retention\_period](#input\_automated\_snapshot\_retention\_period) | (Optional) The number of days that automated snapshots are retained. Set to 0 to disable automated snapshots. | `number` | `7` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | (Optional) The EC2 Availability Zone (AZ) in which you want Amazon Redshift to provision the cluster. | `string` | `null` | no |
| <a name="input_availability_zone_relocation_enabled"></a> [availability\_zone\_relocation\_enabled](#input\_availability\_zone\_relocation\_enabled) | (Optional) If true, the cluster can be relocated to another availability zone, either automatically by AWS or when requested. | `bool` | `false` | no |
| <a name="input_cluster_identifier"></a> [cluster\_identifier](#input\_cluster\_identifier) | (Required) The Cluster Identifier. Must be lowercase and contain only alphanumeric characters and hyphens. | `string` | n/a | yes |
| <a name="input_cluster_parameter_group_name"></a> [cluster\_parameter\_group\_name](#input\_cluster\_parameter\_group\_name) | (Optional) The name of the parameter group to be associated with this cluster. | `string` | `null` | no |
| <a name="input_cluster_subnet_group_name"></a> [cluster\_subnet\_group\_name](#input\_cluster\_subnet\_group\_name) | (Optional) The name of a cluster subnet group to be associated with this cluster. | `string` | `null` | no |
| <a name="input_cluster_type"></a> [cluster\_type](#input\_cluster\_type) | (Optional) The cluster type to use. Either single-node or multi-node. | `string` | `"single-node"` | no |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | (Optional) The version of the Amazon Redshift engine software that you want to use. | `string` | `"1.0"` | no |
| <a name="input_create_parameter_group"></a> [create\_parameter\_group](#input\_create\_parameter\_group) | (Optional) Whether to create a new parameter group for the cluster. | `bool` | `false` | no |
| <a name="input_create_snapshot_schedule"></a> [create\_snapshot\_schedule](#input\_create\_snapshot\_schedule) | (Optional) Whether to create a snapshot schedule for the cluster. | `bool` | `false` | no |
| <a name="input_create_subnet_group"></a> [create\_subnet\_group](#input\_create\_subnet\_group) | (Optional) Whether to create a new subnet group for the cluster. | `bool` | `false` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | (Optional) The name of the first database to be created when the cluster is created. If you do not provide a name, Amazon Redshift will create a default database called dev. | `string` | `"dev"` | no |
| <a name="input_default_iam_role_arn"></a> [default\_iam\_role\_arn](#input\_default\_iam\_role\_arn) | (Optional) The Amazon Resource Name (ARN) for the IAM role that was set as default for the cluster when the cluster was created. | `string` | `null` | no |
| <a name="input_elastic_ip"></a> [elastic\_ip](#input\_elastic\_ip) | (Optional) The Elastic IP (EIP) address for the cluster. Applicable only for single-node clusters. | `string` | `null` | no |
| <a name="input_enable_iam_roles"></a> [enable\_iam\_roles](#input\_enable\_iam\_roles) | (Optional) Whether to use the separate aws\_redshift\_cluster\_iam\_roles resource to manage IAM roles. If false, IAM roles are managed directly on the cluster resource. | `bool` | `false` | no |
| <a name="input_encrypted"></a> [encrypted](#input\_encrypted) | (Optional) Whether the data in the cluster is encrypted at rest. | `bool` | `true` | no |
| <a name="input_enhanced_vpc_routing"></a> [enhanced\_vpc\_routing](#input\_enhanced\_vpc\_routing) | (Optional) If true, enhanced VPC routing is enabled. Forces all COPY and UNLOAD traffic between the cluster and data repositories to go through your VPC. | `bool` | `true` | no |
| <a name="input_final_snapshot_identifier"></a> [final\_snapshot\_identifier](#input\_final\_snapshot\_identifier) | (Optional) The identifier of the final snapshot that is created before deleting the cluster. Required if skip\_final\_snapshot is false. | `string` | `null` | no |
| <a name="input_iam_roles"></a> [iam\_roles](#input\_iam\_roles) | (Optional) A list of IAM Role ARNs to associate with the cluster. A Maximum of 10 can be associated to the cluster at any time. | `list(string)` | `[]` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | (Optional) The ARN for the KMS encryption key. When specifying kms\_key\_id, encrypted needs to be set to true. | `string` | `null` | no |
| <a name="input_log_destination_type"></a> [log\_destination\_type](#input\_log\_destination\_type) | (Optional) The log destination type. Valid values are s3 and cloudwatch. | `string` | `"s3"` | no |
| <a name="input_log_exports"></a> [log\_exports](#input\_log\_exports) | (Optional) The collection of exported log types. Valid values are connectionlog, useractivitylog, and userlog. | `list(string)` | `[]` | no |
| <a name="input_logging_bucket_name"></a> [logging\_bucket\_name](#input\_logging\_bucket\_name) | (Optional) The name of an existing S3 bucket where the log files are to be stored. Must be in the same region as the cluster. | `string` | `null` | no |
| <a name="input_logging_s3_key_prefix"></a> [logging\_s3\_key\_prefix](#input\_logging\_s3\_key\_prefix) | (Optional) The prefix applied to the log file names. | `string` | `null` | no |
| <a name="input_maintenance_track_name"></a> [maintenance\_track\_name](#input\_maintenance\_track\_name) | (Optional) The name of the maintenance track for the restored cluster. | `string` | `"current"` | no |
| <a name="input_manage_master_password"></a> [manage\_master\_password](#input\_manage\_master\_password) | (Optional) Whether to manage the master password with AWS Secrets Manager. When true, AWS manages the master password. | `bool` | `false` | no |
| <a name="input_manual_snapshot_retention_period"></a> [manual\_snapshot\_retention\_period](#input\_manual\_snapshot\_retention\_period) | (Optional) The number of days to retain manual snapshots. Set to -1 for indefinite retention. | `number` | `-1` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | (Required unless manage\_master\_password is true) Password for the master DB user. Must be between 8 and 64 characters. Must contain at least one uppercase letter, one lowercase letter, and one number. Printable ASCII characters except /, @, or ". | `string` | `null` | no |
| <a name="input_master_password_secret_kms_key_id"></a> [master\_password\_secret\_kms\_key\_id](#input\_master\_password\_secret\_kms\_key\_id) | (Optional) The ARN or ID of the KMS key to encrypt the secret containing the master password. Only used when manage\_master\_password is true. | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | (Required unless manage\_master\_password is true) Username for the master DB user. Must be 1-128 alphanumeric characters, start with a letter. | `string` | `null` | no |
| <a name="input_multi_az"></a> [multi\_az](#input\_multi\_az) | (Optional) If true, the cluster will be created in Multi-AZ mode. Applicable for RA3 node types only. | `bool` | `false` | no |
| <a name="input_node_type"></a> [node\_type](#input\_node\_type) | (Required) The node type to be provisioned for the cluster. See https://docs.aws.amazon.com/redshift/latest/mgmt/working-with-clusters.html#working-with-clusters-overview for valid node types. | `string` | n/a | yes |
| <a name="input_number_of_nodes"></a> [number\_of\_nodes](#input\_number\_of\_nodes) | (Optional) The number of compute nodes in the cluster. Required when cluster\_type is multi-node. Must be at least 2 and at most 128. | `number` | `2` | no |
| <a name="input_parameter_group_description"></a> [parameter\_group\_description](#input\_parameter\_group\_description) | (Optional) The description for the parameter group. | `string` | `"Redshift cluster parameter group"` | no |
| <a name="input_parameter_group_family"></a> [parameter\_group\_family](#input\_parameter\_group\_family) | (Optional) The family of the Redshift parameter group. Required if create\_parameter\_group is true. | `string` | `"redshift-1.0"` | no |
| <a name="input_parameter_group_name"></a> [parameter\_group\_name](#input\_parameter\_group\_name) | (Optional) The name of the Redshift parameter group. Required if create\_parameter\_group is true. | `string` | `null` | no |
| <a name="input_parameters"></a> [parameters](#input\_parameters) | (Optional) A list of parameter objects to apply to the parameter group. | <pre>list(object({<br/>    name  = string<br/>    value = string<br/>  }))</pre> | `[]` | no |
| <a name="input_port"></a> [port](#input\_port) | (Optional) The port number on which the cluster accepts incoming connections. | `number` | `5439` | no |
| <a name="input_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#input\_preferred\_maintenance\_window) | (Optional) The weekly time range during which system maintenance can occur, in UTC. Format: ddd:hh24:mi-ddd:hh24:mi. | `string` | `"sun:05:00-sun:06:00"` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | (Optional) If true, the cluster can be accessed from a public network. SECURITY WARNING: Set to false for production environments. | `bool` | `false` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | (Optional) Determines whether a final snapshot is created before the cluster is deleted. | `bool` | `false` | no |
| <a name="input_snapshot_cluster_identifier"></a> [snapshot\_cluster\_identifier](#input\_snapshot\_cluster\_identifier) | (Optional) The name of the cluster the source snapshot was created from. | `string` | `null` | no |
| <a name="input_snapshot_copy_destination_region"></a> [snapshot\_copy\_destination\_region](#input\_snapshot\_copy\_destination\_region) | (Optional) The destination region that you want to copy snapshots to. | `string` | `null` | no |
| <a name="input_snapshot_copy_grant_name"></a> [snapshot\_copy\_grant\_name](#input\_snapshot\_copy\_grant\_name) | (Optional) The name of the snapshot copy grant to use when snapshots of an encrypted cluster are copied to the destination region. | `string` | `null` | no |
| <a name="input_snapshot_copy_retention_period"></a> [snapshot\_copy\_retention\_period](#input\_snapshot\_copy\_retention\_period) | (Optional) The number of days to retain newly copied snapshots in the destination region. Must be between 1 and 35 days. | `number` | `null` | no |
| <a name="input_snapshot_identifier"></a> [snapshot\_identifier](#input\_snapshot\_identifier) | (Optional) The name of the snapshot from which to create the new cluster. | `string` | `null` | no |
| <a name="input_snapshot_schedule_definitions"></a> [snapshot\_schedule\_definitions](#input\_snapshot\_schedule\_definitions) | (Optional) The definition of the snapshot schedule. The definition is made up of schedule expressions (e.g., 'rate(12 hours)' or 'cron(0 12 * * ? *)'). | `list(string)` | `[]` | no |
| <a name="input_snapshot_schedule_description"></a> [snapshot\_schedule\_description](#input\_snapshot\_schedule\_description) | (Optional) The description for the snapshot schedule. | `string` | `"Redshift cluster snapshot schedule"` | no |
| <a name="input_snapshot_schedule_identifier"></a> [snapshot\_schedule\_identifier](#input\_snapshot\_schedule\_identifier) | (Optional) The identifier for the snapshot schedule. Required if create\_snapshot\_schedule is true. | `string` | `null` | no |
| <a name="input_subnet_group_description"></a> [subnet\_group\_description](#input\_subnet\_group\_description) | (Optional) The description for the subnet group. | `string` | `"Redshift cluster subnet group"` | no |
| <a name="input_subnet_group_name"></a> [subnet\_group\_name](#input\_subnet\_group\_name) | (Optional) The name of the subnet group. Required if create\_subnet\_group is true. | `string` | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | (Optional) A list of VPC subnet IDs. Required if create\_subnet\_group is true. | `list(string)` | `[]` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) A map of tags to assign to all resources. | `map(any)` | <pre>{<br/>  "created_by": "terraform",<br/>  "environment": "prod",<br/>  "terraform": "true"<br/>}</pre> | no |
| <a name="input_usage_limits"></a> [usage\_limits](#input\_usage\_limits) | (Optional) A map of usage limit configurations. The key is a unique identifier for the limit. | <pre>map(object({<br/>    feature_type  = string           # The feature type for the limit. Valid values are spectrum, concurrency-scaling, or cross-region-datasharing.<br/>    limit_type    = string           # The type of limit. Valid values are time or data-scanned.<br/>    amount        = number           # The limit amount.<br/>    breach_action = optional(string) # The action when the limit is breached. Valid values are log, emit-metric, and disable.<br/>    period        = optional(string) # The time period for the limit. Valid values are daily, weekly, and monthly.<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | (Optional) A list of Virtual Private Cloud (VPC) security groups to be associated with the cluster. | `list(string)` | `[]` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_allow_version_upgrade"></a> [allow\_version\_upgrade](#output\_allow\_version\_upgrade) | Whether major version upgrades can be applied |
| <a name="output_arn"></a> [arn](#output\_arn) | Amazon Resource Name (ARN) of the cluster |
| <a name="output_automated_snapshot_retention_period"></a> [automated\_snapshot\_retention\_period](#output\_automated\_snapshot\_retention\_period) | The number of days automated snapshots are retained |
| <a name="output_availability_zone"></a> [availability\_zone](#output\_availability\_zone) | The AZ of the cluster |
| <a name="output_cluster_identifier"></a> [cluster\_identifier](#output\_cluster\_identifier) | The Cluster Identifier |
| <a name="output_cluster_namespace_arn"></a> [cluster\_namespace\_arn](#output\_cluster\_namespace\_arn) | The namespace Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_parameter_group_name"></a> [cluster\_parameter\_group\_name](#output\_cluster\_parameter\_group\_name) | The name of the cluster parameter group associated with the cluster |
| <a name="output_cluster_public_key"></a> [cluster\_public\_key](#output\_cluster\_public\_key) | The public key for the cluster |
| <a name="output_cluster_revision_number"></a> [cluster\_revision\_number](#output\_cluster\_revision\_number) | The specific revision number of the database in the cluster |
| <a name="output_cluster_subnet_group_name"></a> [cluster\_subnet\_group\_name](#output\_cluster\_subnet\_group\_name) | The name of the cluster subnet group associated with the cluster |
| <a name="output_cluster_type"></a> [cluster\_type](#output\_cluster\_type) | The cluster type |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | The version of Redshift engine software |
| <a name="output_database_name"></a> [database\_name](#output\_database\_name) | The name of the default database in the cluster |
| <a name="output_dns_name"></a> [dns\_name](#output\_dns\_name) | The DNS name of the cluster |
| <a name="output_encrypted"></a> [encrypted](#output\_encrypted) | Whether the cluster data is encrypted |
| <a name="output_endpoint"></a> [endpoint](#output\_endpoint) | The connection endpoint |
| <a name="output_enhanced_vpc_routing"></a> [enhanced\_vpc\_routing](#output\_enhanced\_vpc\_routing) | Whether enhanced VPC routing is enabled |
| <a name="output_id"></a> [id](#output\_id) | The Redshift Cluster ID |
| <a name="output_kms_key_id"></a> [kms\_key\_id](#output\_kms\_key\_id) | The KMS key ID for encryption |
| <a name="output_master_username"></a> [master\_username](#output\_master\_username) | Username for the master DB user |
| <a name="output_node_type"></a> [node\_type](#output\_node\_type) | The type of nodes in the cluster |
| <a name="output_number_of_nodes"></a> [number\_of\_nodes](#output\_number\_of\_nodes) | The number of compute nodes in the cluster |
| <a name="output_parameter_group_arn"></a> [parameter\_group\_arn](#output\_parameter\_group\_arn) | Amazon Resource Name (ARN) of the Redshift parameter group |
| <a name="output_parameter_group_id"></a> [parameter\_group\_id](#output\_parameter\_group\_id) | The Redshift parameter group ID |
| <a name="output_port"></a> [port](#output\_port) | The port the cluster responds on |
| <a name="output_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#output\_preferred\_maintenance\_window) | The maintenance window |
| <a name="output_publicly_accessible"></a> [publicly\_accessible](#output\_publicly\_accessible) | Whether the cluster is publicly accessible |
| <a name="output_snapshot_schedule_arn"></a> [snapshot\_schedule\_arn](#output\_snapshot\_schedule\_arn) | Amazon Resource Name (ARN) of the Redshift snapshot schedule |
| <a name="output_snapshot_schedule_id"></a> [snapshot\_schedule\_id](#output\_snapshot\_schedule\_id) | The Redshift snapshot schedule ID |
| <a name="output_subnet_group_arn"></a> [subnet\_group\_arn](#output\_subnet\_group\_arn) | Amazon Resource Name (ARN) of the Redshift Subnet group |
| <a name="output_subnet_group_id"></a> [subnet\_group\_id](#output\_subnet\_group\_id) | The Redshift Subnet group ID |
| <a name="output_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#output\_vpc\_security\_group\_ids) | The VPC security group IDs associated with the cluster |
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
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->

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
```
