output "bucket_name" {
  description = "S3 bucket receiving uploads"
  value       = aws_s3_bucket.my_bucket.id
}

output "table_name" {
  description = "DynamoDB table holding file metadata"
  value       = aws_dynamodb_table.ddb_table.name
}

output "rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_api_gateway_rest_api.apigw_get.id
}

output "files_endpoint" {
  description = "Full URL of the GET /files endpoint"
  value       = "${aws_api_gateway_stage.apigw_get_stage.invoke_url}/files"
}
