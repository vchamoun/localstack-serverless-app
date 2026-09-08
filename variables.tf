variable "aws_region" {
  description = "Region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "S3 bucket name (must be globally unique)"
  type        = string
  default     = "s3-localstack-objrepo2"
}

variable "table_name" {
  description = "DynamoDB table name"
  type        = string
  default     = "ddb-filemetadata"
}

variable "lambda_runtime" {
  description = "Python runtime for both functions"
  type        = string
  default     = "python3.12"
}


