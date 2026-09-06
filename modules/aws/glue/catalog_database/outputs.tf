###########################
# Database Outputs
###########################

output "id" {
  description = "Catalog ID and name of the database in the format catalog_id:name."
  value       = aws_glue_catalog_database.this.id
}

output "name" {
  description = "Name of the Glue catalog database."
  value       = aws_glue_catalog_database.this.name
}

output "arn" {
  description = "ARN of the Glue catalog database."
  value       = aws_glue_catalog_database.this.arn
}

output "catalog_id" {
  description = "ID of the Glue Catalog the database lives in."
  value       = aws_glue_catalog_database.this.catalog_id
}
