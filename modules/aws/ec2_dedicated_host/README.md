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
