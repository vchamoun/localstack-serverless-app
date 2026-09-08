
# Create the S3 Bucket
resource "aws_s3_bucket" "my_bucket" {
  bucket = var.bucket_name

  tags = {
    Name        = "LocalStack-ObjRepo"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "my_bucket_privacy" {
  bucket = aws_s3_bucket.my_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Create a simple DynamoDB Table
resource "aws_dynamodb_table" "ddb_table" {
  name         = var.table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "fileName"

  # Define the primary key attribute
  attribute {
    name = "fileName"
    type = "S" # 'S' stands for String. Use 'N' for Number, 'B' for Binary.
  }

  tags = {
    Environment = "Dev"
    ManagedBy   = "Terraform"
  }
}

