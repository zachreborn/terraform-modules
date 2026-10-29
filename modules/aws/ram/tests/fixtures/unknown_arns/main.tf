# The built-in resource's output is unknown during the initial plan, even
# though its input is literal. Do not mock this resource: that would hide the
# for_each regression this fixture exercises.
resource "terraform_data" "upstream" {
  input = "arn:aws:ec2:us-east-1:123456789012:transit-gateway/tgw-0123456789abcdef0"
}

module "ram" {
  source = "../../.."

  name          = "unknown_arn_regression"
  principal     = "123456789012"
  resource_arns = { transit = terraform_data.upstream.output }
}

output "resource_association_ids" {
  value = module.ram.resource_association_ids
}
