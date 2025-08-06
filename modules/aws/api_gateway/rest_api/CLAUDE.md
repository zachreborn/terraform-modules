# API Gateway REST API Terraform Module

This is a Terraform module for creating AWS API Gateway REST APIs with comprehensive configuration options.

## Project Structure

- `main.tf` - Main Terraform configuration with resources for API Gateway, resources, methods, integrations, and VPC links
- `variables.tf` - Input variable definitions
- `outputs.tf` - Output definitions
- `README.md` - Documentation with usage examples and terraform-docs generated reference

## Key Features

- Creates AWS API Gateway REST API with configurable endpoint types (EDGE, REGIONAL, PRIVATE)
- Supports multiple resources, methods, and integrations through maps
- VPC link support for private integrations
- Comprehensive method and integration response configuration
- Binary media type support and compression settings

## Usage

The module uses map-based configuration for resources, methods, integrations, and responses to support multiple endpoints within a single API Gateway.

## Important Notes

- Line 48 in main.tf references `var.resources` but this variable doesn't exist in the documented inputs - this appears to be a bug
- The module is designed to be flexible with optional configurations for most parameters
- Uses dynamic blocks for endpoint configuration when specified

## Commands

- `terraform fmt` - Format Terraform files
- `terraform validate` - Validate configuration
- `terraform plan` - Show planned changes
- `terraform apply` - Apply changes