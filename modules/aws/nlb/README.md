NLB
```hcl
module "nlb" {
  source = "./terraform-modules/modules/aws/nlb"

  name               = "my-nlb"
  internal          = false
  load_balancer_type = "network"
  subnets           = ["subnet-1234", "subnet-5678"]

  enable_cross_zone_load_balancing = true

  tags = {
    Environment = "production"
  }
}
```

For an ALB:

```hcl
module "alb" {
  source = "./terraform-modules/modules/aws/nlb"

  name               = "my-alb"
  internal          = false
  load_balancer_type = "application"
  security_groups    = ["sg-1234"]
  subnets           = ["subnet-1234", "subnet-5678"]

  access_logs = {
    bucket  = "my-alb-logs"
    prefix  = "my-alb"
    enabled = true
  }

  tags = {
    Environment = "production"
  }
}
```
