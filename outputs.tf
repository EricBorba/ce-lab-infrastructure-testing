output "bucket_name" {
  description = "Name of the S3 data store bucket"
  value       = aws_s3_bucket.data_store.id
}

output "bucket_arn" {
  description = "ARN of the S3 data store bucket"
  value       = aws_s3_bucket.data_store.arn
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB lock table"
  value       = aws_dynamodb_table.state_lock.name
}
