output "dynamodb_table_arn" {
  description = "The ARN of the dynamodb table"
  value       = aws_dynamodb_table.movies_db.arn
}