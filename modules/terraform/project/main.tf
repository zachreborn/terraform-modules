terraform {
  required_version = ">= 1.0.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = ">=0.42.0"
    }
  }
}

# Terraform project
resource "tfe_project" "this" {
  name         = var.name
  organization = var.organization
}
