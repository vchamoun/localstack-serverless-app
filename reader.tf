data "archive_file" "reader_init" {
  type        = "zip"
  source_file = "${path.module}/src/read_function.py"
  output_path = "${path.module}/build/read_function.zip"
}

resource "aws_iam_role" "reader_role" {
  name = "reader_role"

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

}

resource "aws_iam_role_policy" "reader_policy" {
  name = "reader_policy"
  role = aws_iam_role.reader_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:getItem",
          "dynamodb:Scan",
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.ddb_table.arn
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "reader_attach" {
  role       = aws_iam_role.reader_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole" #AWS Managed policy
}

resource "aws_lambda_function" "reader_function" {

  filename         = data.archive_file.reader_init.output_path
  function_name    = "reader_lambda_function"
  role             = aws_iam_role.reader_role.arn
  handler          = "read_function.lambda_handler"
  source_code_hash = data.archive_file.reader_init.output_base64sha256

  runtime = var.lambda_runtime

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.ddb_table.name
    }
  }
}

resource "aws_lambda_permission" "reader_allow_apigw" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.reader_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.apigw_get.execution_arn}/*/GET/files"
}
