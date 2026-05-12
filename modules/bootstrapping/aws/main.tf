terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }
  }
}

##############################
# Data Sources
##############################
data "tls_certificate" "terraform_cloud_certificate" {
  url = "https://${var.terraform_cloud_hostname}"
}

##############################
# AWS Identity Provider
##############################
resource "aws_iam_openid_connect_provider" "terraform_cloud" {
  url  = data.tls_certificate.terraform_cloud_certificate.url
  tags = var.tags
  client_id_list = [
    var.terraform_cloud_aws_audience
  ]
  thumbprint_list = [
    data.tls_certificate.terraform_cloud_certificate.certificates[0].sha1_fingerprint
  ]
}

resource "aws_iam_role" "terraform_cloud" {
  name = var.iam_role_name
  tags = var.tags
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17",
    "Statement" = [
      {
        "Effect" = "Allow",
        "Principal" = {
          "Federated" = "${aws_iam_openid_connect_provider.terraform_cloud.arn}"
        },
        "Action" = "sts:AssumeRoleWithWebIdentity",
        "Condition" = {
          "StringEquals" = {
            "${var.terraform_cloud_hostname}:aud" : "${var.terraform_cloud_aws_audience}"
          },
          "StringLike" = {
            "${var.terraform_cloud_hostname}:sub" : "organization:${var.terraform_cloud_organization}:project:${var.terraform_cloud_project_name}:workspace:${var.terraform_cloud_workspace_name}:run_phase:*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "terraform_cloud" {
  role       = aws_iam_role.terraform_cloud.name
  policy_arn = var.terraform_role_policy_arn
}
