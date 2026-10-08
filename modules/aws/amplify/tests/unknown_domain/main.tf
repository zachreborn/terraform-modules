###########################################################
# Harness module proving the amplify module plans when a branch's
# domain_name is known only after apply -- e.g. a domain derived from
# another resource's computed attribute in the same apply.
# terraform_data.output is unknown at plan time, standing in for that
# computed value. (terraform_data.id is not used: core refines it as
# known-non-null, which would mask the null check this harness exists to
# exercise, whereas provider-computed attributes carry no such refinement.)
# Mirrors the harness pattern in
# modules/aws/identity_center/permission_set/tests/computed_ids.
###########################################################

terraform {
  required_version = ">= 1.4.0" # terraform_data
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

resource "terraform_data" "domain" {
  input = "example.org"
}

module "amplify" {
  source = "../.."

  name = "unknown-domain"
  branches = {
    main = {
      domain_name               = terraform_data.domain.output
      enable_domain_association = true # required: a null check on an unknown domain_name is itself unknown
    }
    poc = {
      framework = "Astro"
    }
  }
}

output "branch_urls" {
  description = "branch_urls output of the amplify module."
  value       = module.amplify.branch_urls
}
