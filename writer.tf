data "archive_file" "init" {
  type        = "zip"
  source_file = "${path.module}/src/writer_function.py"
  output_path = "${path.module}/build/writer.zip"
}

resource "aws_iam_role" "writer_role" {
  name = "writer_role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    tag-key = "tag-value"
  }
}

resource "aws_iam_role_policy" "writer_policy" {
  name = "writer_policy"
  role = aws_iam_role.writer_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:PutItem",
          "dynamodb:DeleteItem",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.ddb_table.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "writer-attach" {
  role       = aws_iam_role.writer_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "writer_lambda" {
  filename         = data.archive_file.init.output_path
  function_name    = "writer_lambda_function"
  role             = aws_iam_role.writer_role.arn
  handler          = "writer_function.lambda_handler"
  source_code_hash = data.archive_file.init.output_base64sha256

  runtime = var.lambda_runtime

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.ddb_table.name
    }
  }

  tags = {
    Environment = "production"
    Application = "example"
  }
}

resource "aws_lambda_permission" "writer_permission" {
  statement_id   = "AllowExecutionFromS3Bucket"
  action         = "lambda:InvokeFunction"
  function_name  = aws_lambda_function.writer_lambda.function_name
  principal      = "s3.amazonaws.com"
  source_arn     = aws_s3_bucket.my_bucket.arn
  source_account = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.my_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.writer_lambda.arn
    events = [
      "s3:ObjectCreated:*",
      "s3:ObjectRemoved:*",
    ]
  }

  depends_on = [aws_lambda_permission.writer_permission]
}
